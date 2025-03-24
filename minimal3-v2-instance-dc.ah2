#Requires AutoHotkey v2.0
; 漢字入力システム 最小構成 (direct-input-minimal.ahk)
;  Version: 0.1.0
;  動作確認: AutoHotKey 2.0.19
;  製作: kouie

#SingleInstance Force

class InputSystem {
    inputBuffer := ""    ; 変換用バッファ
    dictionary := Map()  ; 辞書

    matchCount := 0      ; 再変換用
    lastfixKey := ""
    lastfixKey2 := ""
    reCon_able := 0

    active := 1          ; システム関連
    InputDisplay := ""
    static gui1 := ""

    ; システム名（識別用）
    name := ""
    
    ; コンストラクタ
    __New(systemName := "Default") {
        this.name := systemName
        SetTitleMatchMode(2)
        this.Init()
    }

    Init() {
        SetTitleMatchMode(2)

        this.LoadDictionary()
        InputSystem.GUI_init()
        this.UpdateDisplay()
    }

    ; 辞書データの例 (サンプル)
    sample_dictionary() {
        keys := ["tx", "xb", "gw", "qxk"]
        values := ["田中", "小林", "小川", "久子"]
        Loop keys.Length
        {
            this.dictionary[keys[A_Index]] := values[A_Index]
        }
    }

    ; 辞書データをファイルから読み込み
    LoadDictionary() {
        dictionaryFile := ".\dictionary-file.txt"
        dictionaryFile := ".\dictionary-local.txt"
        try {
            content := FileRead(dictionaryFile)
            Loop Parse, content, "`n", "`r" {
                if (A_LoopField = "")
                    continue
                    
                parts := StrSplit(A_LoopField, "=")
                if (parts.Length = 2)
                    this.dictionary[parts[1]] := parts[2]
            }
        } catch Error as e {
            MsgBox("辞書ファイルの読み込みに失敗しました: " e.Message)
        }
    }

    ; 入力バッファの内容を変換
    CheckAndConvert() {
        if (StrLen(this.inputBuffer) == 1){
            return
        }
    
        value := this.dictionary.Has(this.inputBuffer) ? this.dictionary[this.inputBuffer] : ""
        key := this.inputBuffer

        if (value != "") {
            ; BS 回数の計算
            length := StrLen(key)
            if (this.matchCount == 0){
                bsLength := length
            } else {
                bsLength := length - strlen(this.lastFixKey) + strlen(this.dictionary[this.lastFixKey])
            }

            SendInput("{BS " bsLength "}" value)		; 入力行を更新

            ; バッファと変換履歴を更新
            this.reCon_able := 0
            if (this.matchCount > 0){
                ; 再マッチ時 (3 文字)
                this.inputBuffer := ""
                this.matchCount := 0
                this.reCon_able := 1
            }else{
                this.matchCount += 1			; 初回マッチ (2 or 3 文字)
            }
            this.lastFixKey2 := this.lastFixKey
            this.lastFixKey := key
        }else{
            if (this.matchCount == 1) {
                ; 3 文字ではマッチなし、最後の 1 文字残してバッファをクリア
                this.inputBuffer := SubStr(this.inputBuffer, -1)
                this.matchCount := 0
            }
        }
        this.UpdateDisplay()
    }

    ; 直前の変換を対象に、区切り位置を (2 文字目の後に) 変更して再変換
    reConvert(){
        if (this.reCon_able == 1){
            follow_part := this.inputBuffer
            redo_part := SubStr(this.lastFixKey, strLen(this.lastFixKey2) + 1)
            lastFixValue := this.dictionary[this.lastFixKey]
            lastFixValue2 := this.dictionary[this.lastFixKey2]
            backcount := strLen(lastFixValue) + strLen(follow_part)

            ; 入力行を更新: 元に戻した初期変換部分 ＋ 元に戻した 3 文字目の読み ＋ その後に入力された部分
            SendInput("{BS " backcount "}" lastFixValue2 redo_part follow_part)

            ; 変換履歴を一時保存
            lastFixKeyBackup := this.lastFixKey
            lastFixKey2Backup := this.lastFixKey2
            this.clearBuffer()

            ; 入力バッファを更新して変換
            this.inputBuffer := redo_part
            this.inputBuffer .= follow_part
            this.CheckAndConvert()

            ; 変換結果を反映して履歴を更新
            if ( this.lastFixKey == lastFixKeyBackup ){
                this.lastFixKey := lastFixKey2Backup ; 後続の変換なし
            }
            this.lastFixKey2 := lastFixKey2Backup    ; 後続の変換がなかった場合は正しくないが影響ない (履歴も残ってない)
            this.reCon_able := 0

            this.UpdateDisplay()
        }
    }

    ; GUIの作成
    static GUI_init() {
        myGui := Gui("+AlwaysOnTop +ToolWindow -Caption")
        myGui.SetFont("s12")
        myGui.Add("Text", "vInputDisplay w150")
        myGui.Show("NoActivate x0 y0")
        InputSystem.gui1 := myGui
    }

    ; 情報ウィンドウを更新
    UpdateDisplay() {
        ; バッファの内容や変換履歴など
        InputSystem.gui1["InputDisplay"].Value :=  this.name " " this.reCon_able " " this.matchCount " | " this.lastFixKey " - " this.inputBuffer
    }

    ; バッファをクリア
    clearBuffer() {
        this.inputBuffer := ""
        this.matchCount := 0	
        this.reCon_able := 0
    }

    ; BS 入力時にバッファも 1 文字削除
    ; ※ IME 併用時にかな変換が成立している場合は削除する文字の再カウントが必要 (ここでは未対応)
    backspaceBuffer(){
        if(this.inputBuffer == this.lastFixKey){	; 変換直後
            this.clearBuffer()
        }else if (this.inputBuffer == ""){
            this.clearBuffer()
        }else{
            this.inputBuffer := SubStr(this.inputBuffer,1, -1)
            if(this.inputBuffer == ""){
                if (this.reCon_able == 1){
                    this.clearBuffer()
                    this.reCon_able := 1
                }else{
                    this.clearBuffer()
                }
            }
        }
        this.UpdateDisplay()
    }

    ; システムを一時停止
    toggleSuspend(){
        { 
            Suspend
            this.active ^= 1
            if (this.active == 0) {
                this.clearBuffer()
                InputSystem.gui1["InputDisplay"].Value := "SUSPENDED"
                InputSystem.gui1.BackColor := "FF9900"
            } else {
                InputSystem.gui1.BackColor := "E0E0E0"
                this.UpdateDisplay()
            }
        }
    }

    ; システムの再起動
    resetSystem(){
        Reload
    }
}

global system := InputSystem("sys1")

; ホットキーの定義
HotIfWinActive("A")

; 英字
$a::
$b::
$c::
$d::
$e::
$f::
$g::
$h::
$i::
$j::
$k::
$l::
$m::
$n::
$o::
$p::
$q::
$r::
$s::
$t::
$u::
$v::
$w::
$x::
$y::
$z::
$0::
$1::
$2::
$3::
$4::
$5::
$6::
$7::
$8::
$9::
$.::
$-::
$@::
{
    key1 := SubStr(A_ThisHotkey, 2)
    SendInput(key1)
    system.inputBuffer .= key1     ; 入力文字をバッファに追加
    system.UpdateDisplay()
    system.CheckAndConvert()
}

#SuspendExempt
$BS::
^$h::
{
    SendInput("{BS}")
    system.backspaceBuffer()
    system.UpdateDisplay()
}
#SuspendExempt False

$Enter::
$Space::
$Tab::
$Esc::
{
    key := SubStr(A_ThisHotkey, 2)
    SendInput("{" key "}")
    system.clearBuffer()
    system.UpdateDisplay()        
}

; 再変換
^k::
^l::
{
	system.reConvert()
}

#SuspendExempt
; 変換システムの一時停止 
!F12::
^q::
{
    system.toggleSuspend()
}

; 再読み込み (リセット)
!F11::
{
    system.resetSystem()
}
#SuspendExempt False

