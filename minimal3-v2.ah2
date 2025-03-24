#Requires AutoHotkey v2.0
; 漢字入力システム 最小構成 (direct-input-minimal.ahk)
;  Version: 0.1.0
;  動作確認: AutoHotKey 1.1.24.02
;  製作: kouie

SetTitleMatchMode(2)
#SingleInstance Force

global inputBuffer := ""    ; 変換用バッファ
global dictionary := Map()       ; 辞書
global InputDisplay := ""
global active := 1

global matchCount := 0
global lastfixKey := ""
global lastfixKey2 := ""
global reCon_able := 0
global gui1 := ""

; 辞書データの例 (サンプル)
keys := ["tx", "xb", "gw", "qxk"]
values := ["田中", "小林", "小川", "久子"]
Loop keys.Length
{
    dictionary[keys[A_Index]] := values[A_Index]
}

; 実際の辞書データはファイルから読み込む
LoadDictionary() {
    dictionaryFile := ".\dictionary-2only.txt"
    dictionaryFile := ".\dictionary-local.txt"

	content := FileRead(dictionaryFile)
    Loop Parse, content, "`n," "`r"
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length == 2)
            dictionary[parts[1]] := parts[2]
    }
}

; 入力バッファの内容を変換
CheckAndConvert() {
	global inputBuffer, matchCount, lastFixKey, lastFixKey2, reCon_able

    if (StrLen(inputBuffer) == 1){
    	return
    }
   
    value := dictionary.Has(inputBuffer) ? dictionary[inputBuffer] : ""
	key := inputBuffer

	if (value != "") {
        ; BS 回数の計算
		length := StrLen(key)
		if (matchCount == 0){
			bsLength := length
		} else {
			bsLength := length - strlen(lastFixKey) + strlen(dictionary[lastFixKey])
		}

		SendInput("{BS " bsLength "}" value)		; 入力行を更新

        ; バッファと変換履歴を更新
		reCon_able := 0
        if (matchCount > 0){
			; 再マッチ時 (3 文字)
            inputBuffer := ""
	        matchCount := 0
			reCon_able := 1
		}else{
	    	matchCount += 1			; 初回マッチ (2 or 3 文字)
	    }
        lastFixKey2 := lastFixKey
        lastFixKey := key

    }else{
    	if (matchCount == 1) {
    	    ; 3 文字のマッチなし、最後の 1 文字残してバッファをクリア
			inputBuffer := SubStr(inputBuffer, -1)
    		matchCount := 0
		}
	}
	UpdateDisplay()
}

; 直前の変換を対象に、区切り位置を(2文字目の後に)変更して再変換
reConvert(){
	global inputBuffer, lastFixKey, lastFixKey2, reCon_able

	if (reCon_able == 1){
		follow_part := inputBuffer
		redo_part := SubStr(lastFixKey, strLen(lastFixKey2) + 1)
		lastFixValue := dictionary[lastFixKey]
		lastFixValue2 := dictionary[lastFixKey2]
		backcount := strLen(lastFixValue) + strLen(follow_part)

		; 入力行を更新: 元に戻した初期変換部分 ＋ 元に戻した 3 文字目の読み ＋ その後に入力された部分
		SendInput("{BS " backcount "}" lastFixValue2 redo_part follow_part)

		; 変換履歴を一時保存
		lastFixKeyBackup := lastFixKey
		lastFixKey2Backup := lastFixKey2
		clearBuffer()

		; 入力バッファを更新して変換
		inputBuffer := redo_part
		inputBUffer .= follow_part
		CheckAndConvert()

		; 変換履歴を更新
		if ( lastFixKey == lastFixKeyBackup ){
				lastFixKey := lastFixKey2Backup ; 後続の変換なし
		}
		lastFixKey2 := lastFixKey2Backup    ; 後続の変換がなかった場合は正しくないが影響ない (履歴も残ってない)
		reCon_able := 0

		UpdateDisplay()
	}
}

; バッファをクリア
clearBuffer() {
	global
	inputBuffer := ""
	matchCount := 0	
	reCon_able := 0
}

; BS 入力時にバッファも 1 文字削除
; ※ IME 併用時にかな変換が成立している場合は削除する文字の再カウントが必要 (ここでは未対応)
backspaceBuffer(){
	global inputBuffer, lastfixKey, reCon_able
	if(inputBuffer == lastFixKey){	; 変換直後
		clearBuffer()
	}else if (inputBuffer == ""){
		clearBuffer()
	}else{
		inputBuffer := SubStr(inputBuffer,1, -1)
		if(inputBuffer == ""){
			if (reCon_able == 1){
				clearBuffer()
				reCon_able := 1
			}else{
				clearBuffer()
			}
		}
	}
    UpdateDisplay()
}

; GUIの作成
GUI_init() {
	global gui1
    myGui := Gui("+AlwaysOnTop +ToolWindow -Caption")
    myGui.SetFont("s12")
    myGui.Add("Text", "vInputDisplay w200")
    myGui.Show("NoActivate x0 y0")
    gui1 := myGui
}

; 情報ウィンドウを更新
UpdateDisplay() {
	global
    gui1["InputDisplay"].Value := reCon_able " " matchCount " | " lastfixKey " - " inputBuffer
}

handleInput(ThisHotkey){
	global inputBuffer
	key1 := SubStr(A_ThisHotkey, 2)
	SendInput(key1)
	inputBuffer .= key1     ; 入力文字をバッファに追加
	UpdateDisplay()
	CheckAndConvert()
}

; システムを一時停止
toggleSuspend(){
	Suspend
	global active, gui1
	active ^= 1
	if (active == 0) {
		clearBuffer()
		gui1["InputDisplay"].Value := "SUSPENDED"
		gui1.BackColor := "FF9900"
	} else {
		gui1.BackColor := "E0E0E0"
		UpdateDisplay()
	}
}

; システムの再起動
resetSystem(){
	Reload
}

LoadDictionary()
GUI_init()
UpdateDisplay()

; ホットキー定義
; 英文字
Loop 26 {
	key := Chr(96 + A_Index)  ; a-z
	Hotkey("$" key, (*) => handleInput(A_ThisHotkey))
}
; 数字
Loop 10 {
	key := A_Index - 1  ; 0-9
	Hotkey("$" key, (*) => handleInput(A_ThisHotkey))
}
; 記号
Hotkey("$.", (*) => handleInput(A_ThisHotkey))
Hotkey("$-", (*) => handleInput(A_ThisHotkey))

; 1 文字削除
Hotkey("$BS", (*) => (SendInput("{BS}"), backspaceBuffer()) ,"S")
Hotkey("^$h", (*) => (SendInput("{BS}"), backspaceBuffer()) ,"S")

; Esc・確定等でバッファをクリア
Hotkey("$Esc", (*) => (SendInput("{Escape}"), clearBuffer(), UpdateDisplay()))
Hotkey("$Enter", (*) => (SendInput("{Enter}"), clearBuffer(), UpdateDisplay()))
Hotkey("$Space", (*) => (SendInput("{Space}"), clearBuffer(), UpdateDisplay()))
Hotkey("$Tab", (*) => (SendInput("{Tab}"), clearBuffer(), UpdateDisplay()))

; 再変換
Hotkey("^k", (*) => reConvert())
Hotkey("^l", (*) => reConvert())

; 変換システムの一時停止 
Hotkey("!F12", (*) => toggleSuspend(), "S")
Hotkey("^q", (*) => toggleSuspend(), "S")

; 再読み込み (リセット)
Hotkey("!F11", (*) => resetSystem(), "S")
