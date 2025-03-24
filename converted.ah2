#Requires AutoHotkey v2.0
; 漢字入力システム 最小構成 (direct-input-minimal.ahk)
;  Version: 0.1.0
;  動作確認: AutoHotKey v2.0
;  製作: kouie
;  変換: Claude

SetTitleMatchMode(2)

#SingleInstance Force

; グローバル変数の宣言
global inputBuffer := ""    ; 変換用バッファ
global dictionary := Map()  ; 辞書 (v2ではMapオブジェクトを使用)
global InputDisplay := ""
global active := 1

global matchCount := 0
global lastfixKey := ""
global lastfixKey2 := ""
global reCon_able := 0

; 辞書データの例 (サンプル)
; 読みと値を連想配列で格納
keys := ["tx", "xb", "gw", "qxk"]
values := ["田中", "小林", "小川", "久子"]

Loop keys.Length
{
    dictionary[keys[A_Index]] := values[A_Index]
}

; 実際の辞書データはファイルから読み込む
LoadDictionary() {
    dictionaryFile := ".\dictionary-2only.txt"
    ; dictionaryFile := ".\dictionary-local.txt"
    ; dictionaryFile := ".\dictionary_kana.txt"
    
    try {
        content := FileRead(dictionaryFile)
        
        Loop Parse, content, "`n", "`r"
        {
            if (A_LoopField = "")
                continue
                
            parts := StrSplit(A_LoopField, "=")
            if (parts.Length = 2)
                dictionary[parts[1]] := parts[2]
        }
    } catch Error as e {
        MsgBox("辞書ファイルの読み込みに失敗しました: " e.Message)
    }
}

; 入力バッファの内容を変換
CheckAndConvert() {
    if (StrLen(inputBuffer) == 1) {
        return
    }
    
    value := dictionary.Has(inputBuffer) ? dictionary[inputBuffer] : ""
    key := inputBuffer

    if (value != "") {
        ; BS 回数の計算
        length := StrLen(key)
        if (matchCount == 0) {
            bsLength := length
        } else {
            bsLength := length - StrLen(lastFixKey) + StrLen(dictionary[lastFixKey])
        }

        ; 入力行を更新
        SendInput("{BS " bsLength "}" value)

        ; バッファと変換履歴を更新
        reCon_able := 0
        if (matchCount > 0) {
            ; 再マッチ時 (3 文字)
            inputBuffer := ""
            matchCount := 0
            reCon_able := 1
        } else {
            ; 初回マッチ (2 or 3 文字)
            matchCount += 1
        }
        lastFixKey2 := lastFixKey
        lastFixKey := key
    } else {
        if (matchCount == 1) {
            ; 3 文字のマッチなし、最後の 1 文字残してバッファをクリア
            inputBuffer := SubStr(inputBuffer, 0)
            matchCount := 0
        }
    }
    UpdateDisplay()
}

; 直前の変換を対象に、区切り位置を(2文字目の後に)変更して再変換
reConvert() {
    if (reCon_able == 1) {
        follow_part := inputBuffer
        redo_part := SubStr(lastFixKey, StrLen(lastFixKey2) + 1)
        lastFixValue := dictionary[lastFixKey]
        lastFixValue2 := dictionary[lastFixKey2]
        backcount := StrLen(lastFixValue) + StrLen(follow_part)

        ; 入力行を更新: 元に戻した初期変換部分 ＋ 元に戻した 3 文字目の読み ＋ その後に入力された部分
        SendInput("{BS " backcount "}" lastFixValue2 redo_part follow_part)

        ; 変換履歴を一時保存
        lastFixKeyBackup := lastFixKey
        lastFixKey2Backup := lastFixKey2
        clearBuffer()

        ; 入力バッファを更新して変換
        inputBuffer := redo_part
        inputBuffer .= follow_part
        CheckAndConvert()

        ; 変換履歴を更新
        if (lastFixKey == lastFixKeyBackup) {
            lastFixKey := lastFixKey2Backup ; 後続の変換なし
        }
        lastFixKey2 := lastFixKey2Backup    ; 後続の変換がなかった場合は正しくないが影響ない (履歴も残ってない)
        reCon_able := 0

        UpdateDisplay()
    }
}

; バッファをクリア
clearBuffer() {
    inputBuffer := ""
    matchCount := 0    
    reCon_able := 0
}

; BS 入力時にバッファも 1 文字削除
; ※ IME 併用時にかな変換が成立している場合は削除する文字の再カウントが必要 (ここでは未対応)
backspaceBuffer() {
    if (inputBuffer == lastFixKey) {    ; 変換直後
        clearBuffer()
    } else if (inputBuffer == "") {
        clearBuffer()
    } else {
        inputBuffer := SubStr(inputBuffer, 1, -1)
        if (inputBuffer == "") {
            if (reCon_able == 1) {
                clearBuffer()
                reCon_able := 1
            } else {
                clearBuffer()
            }
        }
    }
    UpdateDisplay()
}

; GUIの作成
GUI_init() {
    myGui := Gui("+AlwaysOnTop +ToolWindow -Caption")
    myGui.SetFont("s12")
    myGui.Add("Text", "vInputDisplay w200")
    myGui.Show("NoActivate x0 y0")
    global gui1 := myGui
}

; 情報ウィンドウを更新
UpdateDisplay() {
    gui1["InputDisplay"].Value := reCon_able " " matchCount " | " lastfixKey " - " inputBuffer
}

LoadDictionary()
GUI_init()
UpdateDisplay()

; キーマップ定義
handleInput(ThisHotkey) {
    key1 := SubStr(ThisHotkey, 2)
    SendInput(key1)
    inputBuffer .= key1     ; 入力文字をバッファに追加
    UpdateDisplay()
    CheckAndConvert()
}

; 英数字キーのホットキー定義
$a::handleInput(A_ThisHotkey)
$b::handleInput(A_ThisHotkey)
$c::handleInput(A_ThisHotkey)
$d::handleInput(A_ThisHotkey)
$e::handleInput(A_ThisHotkey)
$f::handleInput(A_ThisHotkey)
$g::handleInput(A_ThisHotkey)
$h::handleInput(A_ThisHotkey)
$i::handleInput(A_ThisHotkey)
$j::handleInput(A_ThisHotkey)
$k::handleInput(A_ThisHotkey)
$l::handleInput(A_ThisHotkey)
$m::handleInput(A_ThisHotkey)
$n::handleInput(A_ThisHotkey)
$o::handleInput(A_ThisHotkey)
$p::handleInput(A_ThisHotkey)
$q::handleInput(A_ThisHotkey)
$r::handleInput(A_ThisHotkey)
$s::handleInput(A_ThisHotkey)
$t::handleInput(A_ThisHotkey)
$u::handleInput(A_ThisHotkey)
$v::handleInput(A_ThisHotkey)
$w::handleInput(A_ThisHotkey)
$x::handleInput(A_ThisHotkey)
$y::handleInput(A_ThisHotkey)
$z::handleInput(A_ThisHotkey)
$0::handleInput(A_ThisHotkey)
$1::handleInput(A_ThisHotkey)
$2::handleInput(A_ThisHotkey)
$3::handleInput(A_ThisHotkey)
$4::handleInput(A_ThisHotkey)
$5::handleInput(A_ThisHotkey)
$6::handleInput(A_ThisHotkey)
$7::handleInput(A_ThisHotkey)
$8::handleInput(A_ThisHotkey)
$9::handleInput(A_ThisHotkey)
$.::handleInput(A_ThisHotkey)
$-::handleInput(A_ThisHotkey)
$@::handleInput(A_ThisHotkey)

; 1 文字削除
$BS::
{
    Suspend(false)
    SendInput("{BS}")
    backspaceBuffer()
}

^h::
{
    Suspend(false)
    SendInput("{BS}")
    backspaceBuffer()
}

; カーソル移動系はバッファをクリアする
$Enter::
{
    SendInput("{Enter}")
    clearBuffer()
    UpdateDisplay()
}

$Space::
{
    SendInput("{Space}")
    clearBuffer()
    UpdateDisplay()
}

$Tab::
{
    SendInput("{Tab}")
    clearBuffer()
    UpdateDisplay()
}

$Esc::
{
    SendInput("{Escape}")
    clearBuffer()
    UpdateDisplay()
}

; 再変換
^k::reConvert()
^l::reConvert()

; 変換システムを一時停止 
!F12::
^q::
{
    Suspend(-1)  ; トグル
    active := !active
    if (active == 0) {
        clearBuffer()
        gui1["InputDisplay"].Value := "SUSPENDED"
        gui1.BackColor := "FF9900"
    } else {
        gui1.BackColor := "E0E0E0"
        UpdateDisplay()
    }
}

; 変換システムをリセット
!F11::
{
    Suspend(false)
    Reload()
}