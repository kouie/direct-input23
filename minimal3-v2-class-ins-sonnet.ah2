#Requires AutoHotkey v2.0
#Warn VarUnset, Off
; 漢字入力システム 最小構成 (direct-input-minimal.ahk) - インスタンスベース版
;  Version: 0.1.0
;  動作確認: AutoHotKey v2.0
;  製作: kouie
;  変換: Claude

#SingleInstance Force

; 入力システムクラス - インスタンス化バージョン
class InputSystem {
    ; インスタンスプロパティ
    inputBuffer := ""        ; 変換用バッファ
    dictionary := Map()      ; 辞書
    active := 1
    matchCount := 0
    lastfixKey := ""
    lastfixKey2 := ""
    reCon_able := 0
    static gui1 := ""                ; GUIオブジェクト
    
    ; システム名（識別用）
    name := ""
    
    ; コンストラクタ
    __New(systemName := "Default") {
        this.name := systemName
        SetTitleMatchMode(2)
        this.Init()
    }
    
    ; システムの初期化
    Init() {
        ; サンプル辞書データの読み込み
        this.LoadSampleDictionary()
        
        ; 実際の辞書データの読み込み
        this.LoadDictionary()
        
        ; GUIの初期化
        InputSystem.GUI_init()
        
        ; 表示の更新
        this.UpdateDisplay()
        
        return this  ; メソッドチェーンができるように自身を返す
    }
    
    ; サンプル辞書データの読み込み
    LoadSampleDictionary() {
        keys := ["tx", "xb", "gw", "qxk", "@tx", "@xb", "@gw", "x@"]
        values := ["田中", "小林", "小川", "久子","田中", "小林", "小川", "久子"]

        Loop keys.Length {
            this.dictionary[keys[A_Index]] := values[A_Index]
        }
        
        return this
    }
    
    ; 実際の辞書データはファイルから読み込む
    LoadDictionary() {
        dictionaryFile := ".\dictionary-2only.txt"
        ; dictionaryFile := ".\dictionary-local.txt"
        ; dictionaryFile := ".\dictionary_kana.txt"
        
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
        
        return this
    }
    
    ; 入力バッファの内容を変換
    CheckAndConvert() {
        if (StrLen(this.inputBuffer) == 1) {
            return this
        }
        
        value := this.dictionary.Has(this.inputBuffer) ? this.dictionary[this.inputBuffer] : ""
        key := this.inputBuffer

        if (value != "") {
            ; BS 回数の計算
            length := StrLen(key)
            if (this.matchCount == 0) {
                bsLength := length
            } else {
                bsLength := length - StrLen(this.lastFixKey) + StrLen(this.dictionary[this.lastFixKey])
            }

            ; 入力行を更新
            SendInput("{BS " bsLength "}" value)

            ; バッファと変換履歴を更新
            this.reCon_able := 0
            if (this.matchCount > 0) {
                ; 再マッチ時 (3 文字)
                this.inputBuffer := ""
                this.matchCount := 0
                this.reCon_able := 1
            } else {
                ; 初回マッチ (2 or 3 文字)
                this.matchCount += 1
            }
            this.lastFixKey2 := this.lastFixKey
            this.lastFixKey := key
        } else {
            if (this.matchCount == 1) {
                ; 3 文字のマッチなし、最後の 1 文字残してバッファをクリア
                this.inputBuffer := SubStr(this.inputBuffer, 0)
                this.matchCount := 0
            }
        }
        this.UpdateDisplay()
        
        return this
    }
    
    ; 直前の変換を対象に、区切り位置を(2文字目の後に)変更して再変換
    reConvert() {
        if (this.reCon_able == 1) {
            follow_part := this.inputBuffer
            redo_part := SubStr(this.lastFixKey, StrLen(this.lastFixKey2) + 1)
            lastFixValue := this.dictionary[this.lastFixKey]
            lastFixValue2 := this.dictionary[this.lastFixKey2]
            backcount := StrLen(lastFixValue) + StrLen(follow_part)

            ; 入力行を更新
            SendInput("{BS " backcount "}" lastFixValue2 redo_part follow_part)

            ; 変換履歴を一時保存
            lastFixKeyBackup := this.lastFixKey
            lastFixKey2Backup := this.lastFixKey2
            this.clearBuffer()

            ; 入力バッファを更新して変換
            this.inputBuffer := redo_part
            this.inputBuffer .= follow_part
            this.CheckAndConvert()

            ; 変換履歴を更新
            if (this.lastFixKey == lastFixKeyBackup) {
                this.lastFixKey := lastFixKey2Backup ; 後続の変換なし
            }
            this.lastFixKey2 := lastFixKey2Backup
            this.reCon_able := 0

            this.UpdateDisplay()
        }
        
        return this
    }
    
    ; バッファをクリア
    clearBuffer() {
        this.inputBuffer := ""
        this.matchCount := 0    
        this.reCon_able := 0
        
        return this
    }
    
    ; BS 入力時にバッファも 1 文字削除
    backspaceBuffer() {
        if (this.inputBuffer == this.lastFixKey) {
            this.clearBuffer()
        } else if (this.inputBuffer == "") {
            this.clearBuffer()
        } else {
            this.inputBuffer := SubStr(this.inputBuffer, 1, -1)
            if (this.inputBuffer == "") {
                if (this.reCon_able == 1) {
                    this.clearBuffer()
                    this.reCon_able := 1
                } else {
                    this.clearBuffer()
                }
            }
        }
        this.UpdateDisplay()
        
        return this
    }
    
    ; GUIの作成
    GUI_init0() {
        myGui := Gui("+AlwaysOnTop +ToolWindow -Caption")
        myGui.SetFont("s12")
        myGui.Add("Text", "vInputDisplay w200")
        myGui.Show("NoActivate x" (A_ScreenWidth - 250) " y" (50 + (this.GetInstanceNumber() * 30)))
        this.gui := myGui
        
        return this
    }

   
    ; GUIの作成
    static GUI_init() {
        myGui := Gui("+AlwaysOnTop +ToolWindow -Caption")
        myGui.SetFont("s12")
        myGui.Add("Text", "vInputDisplay w150")
        myGui.Show("NoActivate x0 y0")
        InputSystem.gui1 := myGui
    }

 
    ; インスタンス番号取得（複数GUI表示用）
    GetInstanceNumber() {
        return StrLen(this.name) * 2  ; 単純な計算でズラす（実際はもっと洗練された方法がよい）
    }
    
    ; 情報ウィンドウを更新
    UpdateDisplay() {
        InputSystem.gui1["InputDisplay"].Value := this.name ": " this.reCon_able " " this.matchCount " | " this.lastfixKey " - " this.inputBuffer
        
        return this
    }
    
    ; キー入力処理
    handleInput(ThisHotkey) {
        key1 := SubStr(ThisHotkey, 2)
        SendInput(key1)
        this.inputBuffer .= key1
        this.UpdateDisplay()
        this.CheckAndConvert()
        
        return this
    }
    
    ; システムの一時停止/再開
    toggleSuspend() {
        Suspend(-1)  ; トグル
        this.active := !this.active
        if (this.active == 0) {
            this.clearBuffer()
            this.gui["InputDisplay"].Value := this.name ": SUSPENDED"
            this.gui.BackColor := "FF9900"
        } else {
            this.gui.BackColor := "E0E0E0"
            this.UpdateDisplay()
        }
        
        return this
    }
}

; インスタンスごとにウィンドウタイプを取得する関数
GetWindowType() {
    if WinActive("ahk_exe notepad.exe")
        return "Notepad"
    else if WinActive("ahk_exe chrome.exe") 
        return "Chrome"
    else if WinActive("ahk_exe firefox.exe")
        return "Firefox"
    else
        return "Default"
}

; インスタンスを保持する変数
global systems := Map()

; 初期インスタンスを作成
systems["Notepad"] := InputSystem("Notepad")
systems["Chrome"] := InputSystem("Chrome")
systems["Firefox"] := InputSystem("Firefox")
systems["Default"] := InputSystem("Default")

; 現在のウィンドウタイプに基づいてインスタンスを取得
GetCurrentSystem() {
    winType := GetWindowType()
    return systems[winType]
}

; ホットキー定義
; 英数字キーのホットキー
HotIfWinActive("A")
Loop 26 {
    key := Chr(96 + A_Index)  ; a-z
    Hotkey("$" key, (*) => GetCurrentSystem().handleInput(A_ThisHotkey))
}

Loop 10 {
    key := A_Index - 1  ; 0-9
    Hotkey("$" key, (*) => GetCurrentSystem().handleInput(A_ThisHotkey))
}

; 記号キー
Hotkey("$.", (*) => GetCurrentSystem().handleInput(A_ThisHotkey))
Hotkey("$-", (*) => GetCurrentSystem().handleInput(A_ThisHotkey))
Hotkey("$@", (*) => GetCurrentSystem().handleInput(A_ThisHotkey))

; バックスペース
Hotkey("$BS", (*) => (Suspend(false), SendInput("{BS}"), GetCurrentSystem().backspaceBuffer()))
Hotkey("^h", (*) => (Suspend(false), SendInput("{BS}"), GetCurrentSystem().backspaceBuffer()))

; カーソル移動系キー
Hotkey("$Enter", (*) => (SendInput("{Enter}"), GetCurrentSystem().clearBuffer(), GetCurrentSystem().UpdateDisplay()))
Hotkey("$Space", (*) => (SendInput("{Space}"), GetCurrentSystem().clearBuffer(), GetCurrentSystem().UpdateDisplay()))
Hotkey("$Tab", (*) => (SendInput("{Tab}"), GetCurrentSystem().clearBuffer(), GetCurrentSystem().UpdateDisplay()))
Hotkey("$Esc", (*) => (SendInput("{Escape}"), GetCurrentSystem().clearBuffer(), GetCurrentSystem().UpdateDisplay()))

; 再変換
Hotkey("^k", (*) => GetCurrentSystem().reConvert())
Hotkey("^l", (*) => GetCurrentSystem().reConvert())

; システム一時停止/再開
Hotkey("!F12", (*) => GetCurrentSystem().toggleSuspend())
Hotkey("^q", (*) => GetCurrentSystem().toggleSuspend())

; システムリセット
Hotkey("!F11", (*) => Reload())

