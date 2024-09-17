SetTitleMatchMode, 2

#SingleInstance, Force

; 変換を有効にするアプリケーショングループを作成
;GroupAdd, userenso, Google Chrome
GroupAdd, userenso, メモ帳

GroupAdd, userenso, 氏名入力
GroupAdd, userenso, データ入力 -
GroupAdd, userenso, お仕事メニュー
GroupAdd, userenso, 自宅で仕事

global dictionaryFile := "dictionary.txt"
global inputBuffer := ""
global dictionary := {}
global matchCount := 0
global lastLength := 0
global lastDispLength := 0
global lastfixKey := ""
global lastfixValue := ""
global lastfixKey2 := ""
global lastfixValue2 := ""
global active := 1
global InputDisplay := ""
global debugMode := 1

; GUIの作成
GUI_init() {
	Gui, +AlwaysOnTop +ToolWindow -Caption
	Gui, Font, s12
	Gui, Add, Text, vInputDisplay w200
	Gui, Show, NoActivate x0 y0
}

;-----------------------------------------------------------
; IMEの状態をセット
;   SetSts          1:ON / 0:OFF
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------
IME_SET(SetSts, WinTitle="A")    {
	ControlGet,hwnd,HWND,,,%WinTitle%
	if	(WinActive(WinTitle))	{
		ptrSize := !A_PtrSize ? 4 : A_PtrSize
	    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
	    NumPut(cbSize, stGTI,  0, "UInt")   ;	DWORD   cbSize;
		hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
	             ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
	}

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
          , UInt, 0x0283  ;Message : WM_IME_CONTROL
          ,  Int, 0x006   ;wParam  : IMC_SETOPENSTATUS
          ,  Int, SetSts) ;lParam  : 0 or 1
}

; 辞書ファイルの読み込み
LoadDictionary(fileName) {
    FileRead, content, %fileName%
    Loop, Parse, content, `n, `r
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length() == 2)
            dictionary[parts[1]] := parts[2]
    }
}

; 情報ウィンドウを更新
UpdateDisplay() {
    GuiControl,, InputDisplay, d:%lastDispLength% b:%lastLength% F2:%lastFixKey2% F1:%lastFixKey% || %inputBuffer% 
}

; 入力バッファの内容を変換
CheckAndConvert() {
    maxLength := 0
    matchedKey := ""
    if (StrLen(inputBuffer) == 1){
    	return
    }
    
    value := dictionary[inputBuffer]
	key := inputBuffer

	if (value != "") {
		matchedKey := key
		length := StrLen(key)
		if (matchCount == 0){
			bsLength := length
			lastLength := length
		} else {
			bsLength := length - lastLength + lastDispLength
			lastLength := length
		}
    }
;;    UpdateDisplay()
    
    if (matchedKey != "") {
    	dicmatch := dictionary[matchedKey]
        SendInput, {BS %bsLength%}%dicmatch%
        if (matchCount > 0){
	        inputBuffer := SubStr(inputBuffer, 1, -maxLength)
	        matchCount := 0
	        lastDispLength := 0
	        lastLength := 0
	    	lastFixKey2 := lastFixKey
	    	lastFixValue2 := lastFixValue
	    	lastFixKey := matchedKey
	    	lastFixValue := dicmatch
	    }else{
	    	matchCount += 1
	    	lastFixKey2 := lastFixKey
	    	lastFixValue2 := lastFixValue
	    	lastFixKey := matchedKey
	    	lastFixValue := dicmatch

	    	lastDispLength := StrLen(dicmatch)
	    	lastFixKey := matchedKey
	    	lastFixValue := dicmatch
	    }
    }else{
    	if (matchCount == 1) {
    		inputBuffer := SubStr(inputBuffer, 0)
    		matchCount := 0
    	}
    }
	UpdateDisplay()
}

;return

; 直前の変換を対象に、区切り位置を(2文字目の後に)変更して再変換
reConvert(){
	if ( StrLen(lastFixKey) > 2 ) {
		if (lastfixKey2 == SubStr(lastfixKey,1,2)) {
			backup := inputBuffer
			backcount := strLen(lastFixValue)+strLen(backup)
			redopart := SubStr(lastFixKey,strLen(lastFixKey2)+1)
			SendInput, {BS %backcount%}%lastFixValue2%%redopart%%backup%
			lastFixKeyBackup := lastFixKey
			lastFixKey2Backup := lastFixKey2

			clearBuffer() 
			inputBuffer := SubStr(lastFixKey,strLen(lastFixKey2)+1)
			inputBUffer .= backup
			CheckAndConvert()
			if ( lastFixKey == lastFixKeyBackup ){
					lastFixKey := lastFixKey2Backup
			}
			lastFixKey2 := lastFixKey2Backup
			UpdateDisplay()
		}
	}
}

; 入力バッファをクリア
clearBuffer() {
	inputBuffer := ""
	lastDispLength := 0
	lastLength := 0
	matchCount := 0	
}

; 読みを検索
searchValue() {
	target := clipboard
	length := StrLen(target)
	if (length < 3){
	    for key, value in dictionary {
	    	if (target == value) {
;			    GuiControl,, InputDisplay, value F2:%lastFixKey2% F1:%lastFixKey% || %inputBuffer% 
				MsgBox, 検索:  %target% `n読み:  %key% `n登録:  %value%
		    	break
	    	}
		}
	}
}


; スクリプトの初期化時に辞書を読み込む
LoadDictionary(dictionaryFile)
GUI_init()

#IfWinActive, ahk_group userenso

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
$@::
$.::
	key1 := SubStr(A_ThisHotkey, 2)
	SendInput, %key1%
	inputBuffer .= SubStr(A_ThisHotkey, 2)
	UpdateDisplay()
	CheckAndConvert()
return

; 直前の変換の区切り位置を変更
^k::
^l::
	reConvert()
return

; 入力バッファから1文字削除 (画面内の未確定も同期)
^h::
	Suspend, Permit

	SendInput, {BS}
	rinputBuffer := inputBuffer
	inputBuffer := SubStr(inputBuffer,1, -1)
	lastDispLength -= 1
	lastLength -= 1
	if(rinputBuffer == lastFixKey){
		clearBuffer()
	}

	if (lastDispLength =< 0){
		clearBuffer()
	}
	UpdateDisplay()
return

; 以下のキーでは入力バッファをクリア
Enter::
	SendInput, {Enter}
	clearBuffer()
	UpdateDisplay()
	
return

Space::
	SendInput, {Space}
	clearBuffer()
	UpdateDisplay()
return

!^Space::
	clearBuffer()
	UpdateDisplay()
return

Tab::
	SendInput, {Tab}
	clearBuffer()
	UpdateDisplay()
return

+Tab::
	SendInput, +{Tab}
	clearBuffer()
	UpdateDisplay()
return


; 変換システムを一時停止 (IMEに切替)
!F12::
	Suspend
	active ^= 1
	if (active == 0) {
		GuiControl,, InputDisplay, SUSPENDED
		Gui, Color, FF9900
		clearBuffer()
		IME_SET(1)
	} else {
		Gui, Color, eeeeee
		UpdateDisplay()
		IME_SET(0)
	}
return

; 変換システムをリセット (IMEはオフ)
!F11::
	Suspend, Permit
	IME_SET(0)
	Reload
return

; 情報ウィンドウの表示/非表示を切替
^!p::
	debugMode ^= 1
	if (debugMode == 0){
		Gui, Hide

	}else{
		Gui, Show, NoActivate
	}
return

^g::
	Suspend, Permit

	Suspend, Off

	IME_SET(0)
	clipboard := ""
	Send, +{Home}^c
	ClipWait,1
	if ErrorLevel
	{
	    return
	}
	searchValue()

	active := 1
	Gui, Color, eeeeee
	UpdateDisplay()
return

^f::
return


^Space::
	Suspend
	active ^= 1
	if (active == 0) {
		GuiControl,, InputDisplay, SUSPENDED
		Gui, Color, FF9900
		clearBuffer()
		IME_SET(1)
	} else {
		Gui, Color, eeeeee
		UpdateDisplay()
		IME_SET(0)
	}
return


#IfWinActive


#ifWinNotActive, ahk_group userenso
^h::SendInput {BS}
#IfWinActive

;#ifWinNotActive, 名刺データ入力｜レゴエントリー
;^Space::
;	Suspend
;	active ^= 1
;	if (active == 0) {
;		GuiControl,, InputDisplay, SUSPENDED
;		Gui, Color, FF9900
;		clearBuffer()
;		IME_SET(1)
;	} else {
;		Gui, Color, eeeeee
;		UpdateDisplay()
;		IME_SET(0)
;	}
;return
;
;#ifWinNotActive
