; 漢字入力システム (direct-input23.ahk)
;  Version: 1.1.0
;  動作確認: AutoHotKey 1.1.24.02
;  製作: kouie

#NoEnv
SetTitleMatchMode, 2

#SingleInstance, Force

global dictionaryFile := ""
global historyfile := ""
global inputBuffer := ""
global dictionary := {}
global dictionaryKana := {}
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
global historyBuffer := ""	; 変換履歴バッファ (随時書き出す)
global reconBuffer := ""	; 再変換履歴バッファ
global moniterTimer := 300000
global logEnable := 0		; 0: ログ出力無効、1: 有効
global iniFile := "direct-input23.ini"
global FileSets := ""
global CurrentSet := 0
global ConvMode := 9
global SentenceMode := 8
global F1ConvMode := 16
global F1SentenceMode := 0
global imeStatus := 0
global f1mode := 0
global kanaDicFile := ""

; GUIの作成
GUI_init() {
	Gui, 1:New, +AlwaysOnTop +ToolWindow -Caption
	Gui, 1:Font, s12
	Gui, 1:Add, Text, vInputDisplay w200
	Gui, 1:Show, NoActivate x0 y0
}

;-----------------------------------------------------------
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF
;-----------------------------------------------------------
IME_GET(WinTitle="A")  {
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
          ,  Int, 0x0005  ;wParam  : IMC_GETOPENSTATUS
          ,  Int, 0)      ;lParam  : 0
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

;-------------------------------------------------------
; IME 入力モードセット
;   ConvMode        入力モード
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;--------------------------------------------------------
IME_SetConvMode(ConvMode,WinTitle="A")   {
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
          , UInt, 0x0283      ;Message : WM_IME_CONTROL
          ,  Int, 0x002       ;wParam  : IMC_SETCONVERSIONMODE
          ,  Int, ConvMode)   ;lParam  : CONVERSIONMODE
}

;----------------------------------------------------------------
; IME 変換モードセット
;   SentenceMode
;       MS-IME  0:無変換 1:人名/地名               8:一般    16:話し言葉
;       ATOK系  0:固定   1:複合語           4:自動 8:連文節
;       WXG              1:複合語  2:無変換 4:自動 8:連文節
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------------
IME_SetSentenceMode(SentenceMode,WinTitle="A")  {
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
          , UInt, 0x0283          ;Message : WM_IME_CONTROL
          ,  Int, 0x004           ;wParam  : IMC_SETSENTENCEMODE
          ,  Int, SentenceMode)   ;lParam  : SentenceMode
}

; INI ファイルからログ・グループを読み込み
LoadInifile() {
		IniRead, moniterTimer, %iniFile%, MonitorTimer, timer
		IniRead, logEnable, %iniFile%, LogEnable, enable
		IniRead, allgroup, %iniFile%, Group, group
		Loop, Parse, allgroup, `,
		{
			GroupAdd, directinput, %A_LoopField%
		}
		IniRead, ConvMode, %iniFile%, ConvMode, mode
		IniRead, SentenceMode, %iniFile%, SentenceMode, mode
		IniRead, F1ConvMode, %iniFile%, F1ConvMode, mode
		IniRead, F1SentenceMode, %iniFile%, F1SentenceMode, mode
		IniRead, kanaDicFile, %iniFile%, kanaDictionary, dict
  }

; INIファイルから前回終了時のセット番号を読み込む
LoadCurrent() {
	set = 1
	IniRead, set, %iniFile%, Currentset, set
	return set
  }

; INIファイルからファイルセット情報を読み込む
LoadFileSets() {
	FileSets := []
	IniRead, Sections, %iniFile%
	Loop, Parse, Sections, `n
	{
		SectionName := A_LoopField
		IfInString, SectionName, Fileset
		{
			IniRead, SetName, %iniFile%, %SectionName%, name
			IniRead, DictFile, %iniFile%, %SectionName%, dict
			IniRead, LogFile, %iniFile%, %SectionName%, log
			FileSets.Push({name: SetName, dict: DictFile, log: LogFile})
		}
	}
	return FileSets
  }

; ファイルセット切り替え関数
SwitchFileSet(index) {
	if (index > 0 && index <= FileSets.Length()) {
		For, key, value in dictionary
		{
			if (CurrentSet != index){
				name := FileSets[index].name
				MsgBox, 4, 確認, 辞書とログファイルを %index% 番「%name%」セット に切り替えます
				IfMsgBox, No
					return 0
			} else {
				return 0
			}
			break
		}
		CurrentSet := index
		dictionaryFile := FileSets[CurrentSet].dict
		historyfile := Filesets[CurrentSet].log
	} else {
		return 0
	}
	return 1
}

; 辞書ファイルの読み込み
LoadDictionary(set) {
	FileRead, content, %dictionaryFile%
	dictionary := {}
    Loop, Parse, content, `n, `r
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length() == 2)
            dictionary[parts[1]] := parts[2]
    }
}

LoadDictionaryKana() {
	FileRead, content, %kanaDicFile%
	dictionaryKana := {}
    Loop, Parse, content, `n, `r
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length() == 2)
			kana := StrSplit(parts[2],",")
            dictionaryKana[parts[1]] := {hira: kana[1], kata: kana[2]}
    }
}


; 情報ウィンドウを更新
UpdateDisplay() {
;    GuiControl, 1:, InputDisplay, S:%CurrentSet% m:%matchCount% F2:%lastFixKey2% F1:%lastFixKey% || %inputBuffer% 
    GuiControl, 1:, InputDisplay, ｾｯﾄ%CurrentSet% ﾏｴ[%lastFixKey%]  || %inputBuffer% 
}

; 履歴ファイルへの書き込み部分
WriteFile(string){
	FileAppend %string%, %historyfile%, UTF-8
	return
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

;			historyBuffer := SubStr(historyBuffer, 1, -bsLength+1)	; +1 は変換前に画面に表示された分(引きすぎ)
			historyBuffer := SubStr(historyBuffer, 1, -bsLength)	; 変換区切りのスペースを入れたので↑から -1
			historyBuffer .= value . " "							; 区切りなしなら -bsLength+1 の方
		}else{
	    	matchCount += 1
	    	lastFixKey2 := lastFixKey
	    	lastFixValue2 := lastFixValue
	    	lastFixKey := matchedKey
	    	lastFixValue := dicmatch

	    	lastDispLength := StrLen(dicmatch)
	    	lastFixKey := matchedKey
	    	lastFixValue := dicmatch

			historyBuffer .= value . " "
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
	if (lastDispLength >=0){
		if ( StrLen(lastFixKey) > 2 ) {
			if (lastfixKey2 == SubStr(lastfixKey,1,2)) {
				backup := inputBuffer
				backcount := strLen(lastFixValue)+strLen(backup)
				redopart := SubStr(lastFixKey,strLen(lastFixKey2)+1)
				SendInput, {BS %backcount%}%lastFixValue2%%redopart%%backup%
				lastFixKeyBackup := lastFixKey
				lastFixKey2Backup := lastFixKey2

				historyBuffer := SubStr(historyBuffer, 1, -strLen(lastFixValue)-1)	;  区切りなしなら -1 なし
				historyBuffer .= lastFixValue2 . " "
				reconBuffer .= lastFixValue . " "

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
}

; 入力バッファをクリア
clearBuffer() {
	inputBuffer := ""
	lastDispLength := 0
	lastLength := 0
	matchCount := 0	
}

; 読みの検索
searchValue() {
	target := clipboard
	length := StrLen(target)
	if (length < 4){
	    for key, value in dictionary {
	    	if (target == value) {
				key_str := ""
				Loop, Parse, key,
				{
					key_str .= A_LoopField . " "
				}
				MsgBox, 検索:  %target% `n読み:  %key_str% `n登録:  %value%
		    	break
	    	}
		}
	}
}

; 変換履歴をファイルへ出力
writeLogs() {
	if (logEnable == 0){
		historyBuffer := ""		
		reconBuffer := ""
		return
	}

	if(historyBuffer){
		FormatTime, timeString, , yyyy-MM-dd HH:mm:ss
		str := timeString . "`n" . historyBuffer . "`n"
		WriteFile(str)
		historyBuffer := ""
	}

	if(reconBuffer){
		FormatTime, timeString, , yyyy-MM-dd HH:mm:ss
		str := "rc " . timeString . "`nrc " . reconBuffer . "`n"
		WriteFile(str)
		reconBuffer := ""
	}
}

; 単語の登録・修正
updateDictionary(){
    ; クリップボードから置換文字列を取得
    newEntry := Clipboard

    ; 入力フォーマットチェック (「英数=日本語」の形式)
    if (!RegExMatch(newEntry, "^[a-z0-9]+=[\p{Han}\p{Hiragana}\p{Katakana}]+$"))
    {
        MsgBox, 48, エラー, 形式が正しくありません。 `n「英(小)字または数字=登録語句」の形式で入力してください。
        return
    }

    ; ファイルパスを指定
    filePath := dictionaryFile

    ; ファイルの内容を読み込む
    FileRead, fileContent, %filePath%

    ; 新しいエントリのキー (= の左側) を取得
    newKey := RegExReplace(newEntry, "=.*$")

    ; ファイル内で完全一致するエントリを検索
    if (RegExMatch(fileContent, "m)^" . newEntry . "$"))
    {
        MsgBox, 48, 情報, このエントリは既に登録されています。
        return
    }

    ; ファイル内でキーが一致するエントリを検索
    foundPos := RegExMatch(fileContent, "m)^" . newKey . "=.*$", oldEntry)

    if (foundPos > 0)
    {
        ; 一致するエントリがある場合、置換の確認
		setname := FileSets[CurrentSet].Name
        MsgBox, 4, 確認, 次のエントリを修正します。よろしいですか？`n`n辞書セット: %setname% ( %dictionaryFile% ) `n変更前: %oldEntry%`n変更後: %newEntry%
        IfMsgBox, No
            return

        ; 置換を実行 (完全一致するものだけを置換)
        newContent := RegExReplace(fileContent, "m)^" . oldEntry . "$", newEntry)
    }
    else
    {
        ; 一致するエントリがない場合、追加の確認
		setname := FileSets[CurrentSet].Name		
        MsgBox, 4, 確認, 次のエントリを追加します。よろしいですか？`n`n辞書セット: %setname% ( %dictionaryFile% ) `n追加: %newEntry%
        IfMsgBox, No
            return

        ; ファイルの末尾に追加 (既存の内容の最後に改行があるか確認)

;		test := SubStr(fileContent, 0)
        if (SubStr(fileContent, 0) != "`n")
            newContent := fileContent . "`r`n" . newEntry
        else
            newContent := fileContent . newEntry
    }

    ; 新しい内容をファイルに書き込む、バックアップも作成
	FormatTime, timeString, , yyyyMMdd-HHmmss
	parts := StrSplit(filepath, "\")
	filename := parts[parts.length()]
	backupFilename := "dic_backup\" . timestring . "-" . filename
	FileCopy, %filePath%, %backupFilename%
    FileDelete, %filePath%
    FileAppend, %newContent%, %filePath%, UTF-8

    MsgBox, 辞書ファイルを更新しました

	clearBuffer()
	LoadDictionary(CurrentSet)
	UpdateDisplay()
;	writeandreload()
}

; ファイルセットを変更
changefileset(set){
	writeLogs()
	stat := SwitchFileSet(set)
	if (stat == 1){
		LoadDictionary(set)
	}
	clearBuffer()
	UpdateDisplay()
}

; 変換履歴と現在のセット番号を出力してから再起動
writeandreload(){
	writeLogs()
	IniWrite, %CurrentSet%, %iniFile%, Currentset, set
	Reload
}


; ドロップダウンリストの選択肢を作成
CreateDropDownList() {
	list := ""
	Loop, % FileSets.Length()
	{
		list .= A_Index . " " . FileSets[A_Index].name . "|"
		if (counter == CurrentSet){
			list .= "|"
		}
	}	
		return RTrim(list, "|")
}
  
; GUI を作成する関数
CreateGui() {
;    global FileSets, CurrentSet
    Gui, 2:New
	Gui, 2:Font, s12
	Gui, 2:Add, DropDownList, vSelectedSet gSwitchSetFromGui, % CreateDropDownList()
    GuiControl, 2:Choose, SelectedSet, %CurrentSet%
    Gui, 2:Show
}

; カナ変換本体
;  文字列の先頭にあるアルファベット以外は無視する
ConvertKana(targetBuffer, hiraKata){
	head := RegExMatch(targetBuffer, "[a-zA-Z]")
	workingBuffer := substr(targetBuffer, head)

	kanaset := "hira"
	if (hiraKata == 2){
		kanaset := "kata"
	} 
	convertedKana := ""
	part := ""
	Loop, {
		if (workingBuffer = "") {
				break
		} else {
			partCounter := 1
			Loop, {
				if (partCounter > StrLen(workingBuffer) or workingBuffer = "") {
					convertedKana .= substr(workingBuffer, 1, 1)
					workingBuffer := substr(workingBuffer, 2)
					break
				}
				part := substr(workingBuffer, 1, partCounter)
				if (part)
					kana := dictionaryKana[part][kanaset]
				if  (kana != "") {
					convertedKana .= kana
					workingBuffer := substr(workingBuffer, partCounter+1 )
					break
				}
				partCounter += 1
			}
		}
	}
	bslength := StrLen(targetBuffer)
	SendInput, {BS %bslength%}
	SendInput, %convertedKana%
	clearbuffer()
	UpdateDisplay()
}

; カナ変換 hiraKata=1: ひらがな or hiraKata=2: カタカナ
kanaConvert(hiraKata){
	target := inputBuffer
	convertKana(target, hiraKata)
}

; 先頭の数字を追い出して変換
kickandConvert(){
	head := RegExMatch(inputBuffer, "[a-z]")
	targetBuffer := substr(inputBuffer, head)
	bslength := StrLen(targetBuffer)
	SendInput, {BS %bslength%}

	clearBuffer()
	Loop, Parse, targetBuffer
	{
		inputBuffer .= A_LoopField
		SendInput, %A_LoopField%
		CheckAndConvert()
	}
	UpdateDisplay()
}

; バッファの先頭 1 文字を追い出して変換
shrinkandConvert(){
	targetBuffer := substr(inputBuffer, 2)
	bslength := StrLen(targetBuffer)
	SendInput, {BS %bslength%}

	clearBuffer()
	Loop, Parse, targetBuffer
	{
		inputBuffer .= A_LoopField
		SendInput, %A_LoopField%
		CheckAndConvert()
	}
	UpdateDisplay()
}

; バッファの先頭 1 文字を削除して変換
deleteandConvert(){
	targetBuffer := substr(inputBuffer, 2)
	bslength := StrLen(inputBuffer)
	SendInput, {BS %bslength%}

	clearBuffer()
	Loop, Parse, targetBuffer
	{
		inputBuffer .= A_LoopField
		SendInput, %A_LoopField%
		CheckAndConvert()
	}
	UpdateDisplay()
}

; スクリプトの初期化時に ini ファイルを読み込む
FileSets := LoadFileSets()
CurrentSet := LoadCurrent()
changefileset(CurrentSet)
LoadDictionary(CurrentSet)
LoadInifile()
LoadDictionaryKana()

GUI_init()
UpdateDisplay()

#IfWinActive, ahk_group directinput

SetTimer, CheckHistory, %moniterTimer% ; 60 秒間隔でチェック

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
	key1 := SubStr(A_ThisHotkey, 2)
	SendInput, %key1%
	if (IME_GET() == 0){
;		inputBuffer .= SubStr(A_ThisHotkey, 2)
		inputBuffer .= key1
		UpdateDisplay()
		CheckAndConvert()
	}
return

$+a::
$+b::
$+c::
$+d::
$+e::
$+f::
$+g::
$+h::
$+i::
$+j::
$+k::
$+l::
$+m::
$+n::
$+o::
$+p::
$+q::
$+r::
$+s::
$+t::
$+u::
$+v::
$+w::
$+x::
$+y::
$+z::
	key1 := SubStr(A_ThisHotkey, 3)
	StringUpper, key, key1
	SendInput, %key%
	inputBuffer .= key
	UpdateDisplay()
return

$,::
	key1 := SubStr(A_ThisHotkey, 2)

	if (IME_GET() == 1){
		SendInput, %key1%
	}else{
		if ( inputBuffer == "" or inputBuffer == lastfixKey){
			clearBuffer()
			SendInput, %key1%
			inputBuffer .= key1
		} else {
			vpos := RegExMatch(inputBuffer, "[a-zA-Z0-9]")
			if (vpos == 1){
;				keys := Substr(inputBuffer, 1)
				clearBuffer()
				SendInput, %key1%
				inputBuffer .= key1
			} else {
				keys := Substr(inputBuffer, 2)

				bslength := StrLen(inputBuffer)
				SendInput, {BS %bslength%}%keys%
				clearBuffer()
			}
		} 
	}
	UpdateDisplay()
return


; 直前の変換の区切り位置を変更
^k::
^l::
	reConvert()
return

; 入力バッファから 1 文字削除 (画面内の未確定も同期)
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

	UpdateDisplay()
return

; 以下のキーでは入力バッファをクリア

Enter::
	SendInput, {Enter}
	clearBuffer()
	UpdateDisplay()
	
return

vk1Dsc07B::
	SendInput, {Left}
	clearBuffer()
	UpdateDisplay()
Return

vk1Csc079::
	SendInput, {Right}
	clearBuffer()
	UpdateDisplay()
Return


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


; 変換システムを一時停止 
!F12::
	Suspend
	active ^= 1
	if (active == 0) {
		GuiControl,, InputDisplay, SUSPENDED
		Gui, 1:Color, FF9900
		clearBuffer()
	} else {
		Gui, 1:Color, E0E0E0
		UpdateDisplay()
	}
return

; [半角/全角] キー
vkF4sc029::
;	SendInput, {vkF4sc029}
	if (imeStatus == 0){
		Gui, 1:Color, C0C000
		IME_SET(1)
		IME_SetConvMode(ConvMode) 
		IME_SetSentenceMode(SentenceMode)
	}else{
		Gui, 1:Color, E0E0E0
		IME_SET(0)
	}
	imeStatus ^= 1
	f1mode := 0
	UpdateDisplay()
return

; [半角/全角] キー
vkF3sc029::
;	SendInput, {vkF3sc029}
	if (imeStatus == 0){
		Gui, 1:Color, C0C000
		IME_SET(1)
		IME_SetConvMode(ConvMode) 
		IME_SetSentenceMode(SentenceMode)
	}else{
		Gui, 1:Color, E0E0E0
		IME_SET(0)
	}
	imeStatus ^= 1
	f1mode := 0
	UpdateDisplay()
return

; IME 入力モード固定
F1::
;	SendInput, {vkF3sc029}
	if (f1mode == 0){
		Gui, 1:Color, 40C0C0
		IME_SET(1)
		IME_SetConvMode(F1ConvMode) 
		IME_SetSentenceMode(F1SentenceMode)
	}
	f1mode := 1
	imeStatus := 1
	UpdateDisplay()
return


; 変換システムをリセット (IME はオフ)
!F11::
	Suspend, Permit
	IME_SET(0)
	writeandreload()
return

; 情報ウィンドウの表示/非表示を切替
^!p::
	debugMode ^= 1
	if (debugMode == 0){
		Gui, 1:Hide

	}else{
		Gui, 1:Show, NoActivate
	}
return

; 漢字の読みを検索 (カーソル位置から 1 文字戻って検索)
^g::
	Suspend, Permit

	Suspend, Off

	IME_SET(0)
	clipboard := ""
	Send, +{LEFT}^c
	ClipWait,1
	if ErrorLevel
	{
	    return
	}
	searchValue()

	active := 1
	Gui, 1:Color, E0E0E0
	UpdateDisplay()
return

; 変換履歴を強制出力
!F9::
	writeLogs()
	return

; 変換履歴を出力 (タイマー処理)
CheckHistory:
	if (A_TimeIdlePhysical > 10000)	{
		writeLogs()
		clearBuffer()
		UpdateDisplay()
	}
return

  ; ドロップダウンリストの選択変更時の処理
  SwitchSet:
	Gui, 2:Submit, NoHide
	index := SubStr(SelectedSet, 8)  ; "FileSetX" から数字部分を取り出す
	changefileset(index)
	Gui, 2:Hide
  return

; 辞書登録
^F8::
	updateDictionary()
return

; 辞書ファイルセット 1 番
!F1::
	changefileset(1)
Return

; 辞書ファイルセット 2 番
!F2::
	changefileset(2)
Return

; 辞書ファイルセット選択ダイアログ
!F3::
	CreateGui()
return

; ひらがな変換
!o::
	kanaConvert(1)
Return

; カタカナ変換
!i::
	kanaConvert(2)
Return

!e::
	kickandConvert()
Return

!s::
	shrinkandConvert()
Return

!d::
	deleteandConvert()
Return


; ドロップダウンリストの選択変更時の処理
SwitchSetFromGui:
    Gui, 2:Submit, NoHide
	index := SubStr(SelectedSet, 1, 1)  ; "FileSetX" から数字部分を取り出す
	changefileset(index)	
	Gui, 2:Hide
	updateDisplay()
return



#IfWinActive

; 対象外のウィンドウの ^h
#ifWinNotActive, ahk_group directinput
^h::SendInput {BS}
#IfWinActive

