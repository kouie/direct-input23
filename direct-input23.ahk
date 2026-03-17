#Requires AutoHotkey v2.0
; 漢字入力システム (direct-input23.ahk) 
;  Version: 2.0.0 (AutoHotkey v2 対応)
;  動作確認: AutoHotKey 2.0.19
;  製作: kouie

SetTitleMatchMode(2)
#Include Misc.ahk
#SingleInstance Force

global dictionaryFile := ""
global historyfile := ""
global inputBuffer := ""
global dictionary := Map()
global dictionaryKana := Map()
global matchCount := 0
global lastfixKey := ""
global lastfixKey2 := ""
global reCon_able := 0
global active := 1
global textInputDisplay := ""
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
global inputMode := "kanji"
global yomiBuffer := ""
global dictionaryJyoyoKanji := []
global lookupDisplay := ""
global lookupResults := []
global lookingActive := 0
global gui1 := ""
global lookupPanel := ""

; GUIの作成
GUI_init() {
	global gui1, lookupPanel

	mygui := Gui()
	WinSetTransparent(180, mygui)
	mygui.Opt("+AlwaysOnTop +ToolWindow -Caption")
	myGui.Title := "DI-buffer-monitor"
	mygui.SetFont("s12")
	mygui.Add("Text", "vtextInputDisplay w200")
	mygui.Show("NoActivate x0 y0")
	gui1 :=mygui

	mygui := Gui("+AlwaysOnTop +ToolWindow -Caption")
	mygui.SetFont("s14")
	mygui.BackColor := "a0e0a0"
	mygui.Add("Text", "vlookupDisplay w50 h550")
	WinSetTransparent(200, mygui)
	lookupPanel := mygui
}


; INI ファイルからログ・グループを読み込み
LoadInifile() {
	global ConvMode, SentenceMode, F1ConvMode, F1SentenceMode, kanaDicFile, moniterTimer, logEnable, iniFile

		moniterTimer := IniRead(iniFile, "MonitorTimer", "timer", 300000)
		logEnable := IniRead(iniFile, "LogEnable", "enable", 1)
		allgroup := IniRead(iniFile, "Group", "group", "")
		Loop Parse, allgroup, ","
		{
			GroupAdd("directinput", A_LoopField)
		}
		ConvMode := IniRead(iniFile, "ConvMode", "mode", 25)
		SentenceMode := IniRead(iniFile, "SentenceMode", "mode", 8)
		F1ConvMode := IniRead(iniFile, "F1ConvMode", "mode", 16)
		F1SentenceMode := IniRead(iniFile, "F1SentenceMode", "mode", 0)
		kanaDicFile := IniRead(iniFile, "kanaDictionary", "dict", "dictionary-hirakata.txt")
  }

; INIファイルから前回終了時のセット番号を読み込む
LoadCurrent() {
	global iniFile
	set := 1
	set := IniRead(iniFile, "Currentset", "set", 1)
	return set
  }

; INIファイルからファイルセット情報を読み込む
LoadFileSets() {
	global FileSets, iniFile

	FileSets := []
	Sections := IniRead(iniFile)
	Loop Parse, Sections, "`n"
	{
		SectionName := A_LoopField
		if InStr(SectionName, "Fileset")
		{
			SetName := IniRead(iniFile, SectionName, "name", "漢字")
			DictFile := IniRead(iniFile, SectionName, "dict", "dictionary-local.txt")
			LogFile := IniRead(iniFile, SectionName, "log", "convert_history.txt")
			FileSets.Push({name: SetName, dict: DictFile, log: LogFile})
		}
	}
	return FileSets
  }

; ファイルセット切り替え関数
SwitchFileSet(index) {
	global dictionary, dictionaryFile, historyfile, CurrentSet, FileSets

	if (index > 0 && index <= FileSets.Length) {
		For key, value in dictionary
		{
			if (CurrentSet != index){
				name := FileSets[index].name
				msgResult := MsgBox("辞書とログファイルを " index " 番「" name "」セット に切り替えます", "確認", 4)
				if (msgResult = "No")
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
	global dictionary, dictionaryFile

	content := FileRead(dictionaryFile)
    Loop Parse, content, "`n", "`r"
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length == 2)
            dictionary[parts[1]] := parts[2]
    }
}

LoadDictionaryKana() {
	global dictionaryKana, kanaDicFile

	content := FileRead(kanaDicFile)

    Loop Parse, content, "`n", "`r"
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length == 2)
			kana := StrSplit(parts[2],",")
			dictionaryKana[parts[1]] := Map("hira", kana[1], "kata", kana[2])
    }
}


; 情報ウィンドウを更新
UpdateDisplay() {
	global gui1, CurrentSet, lastfixKey, inputBuffer, yomiBuffer 
	gui1["textInputDisplay"].Value := "ｾｯﾄ" CurrentSet "前[" lastFixKey "] || " inputBuffer " | " yomiBuffer
}

; 情報パネルの表示を切り替え
toggleInfoPanel(){
	global debugMode, gui1

	debugMode += 1
	if (debugMode > 2){
		debugMode := 0
	}
	if (debugMode == 0) {
		gui1.Opt("+LastFound")
		gui1.Hide()
	} else if (debugMode == 1) {
		title := WinGetTitle("A")
		gui1.Opt("+LastFound -Caption")
		gui1.Show("NoActivate h34")
		WinActivate(title)
	} else {
		title := WinGetTitle("A")
		gui1.Opt("+LastFound +Caption")
		gui1.Show("NoActivate h34")
		WinActivate(title)
	}
}

; 履歴ファイルへの書き込み部分
WriteFile(string){
	global historyfile

	FileAppend(string, historyfile, "UTF-8")
	return
}

; 入力バッファの内容を変換
CheckAndConvert() {
	global inputBuffer, dictionary, matchCount, reCon_able, historyBuffer, lastFixKey, lastfixKey2

    if (StrLen(inputBuffer) == 1){
    	return
    }
   
    value := dictionary.Has(inputBuffer) ? dictionary[inputBuffer] : ""
	if (value != "")
	key := inputBuffer

	if (value != "") {
        ; BS 回数の計算
		length := StrLen(key)
		if (matchCount == 0){
			bsLength := length
		} else {
;			bsLength := length - strlen(lastFixKey) + strlen(dictionary[lastFixKey])
			bsLength := length - strlen(lastFixKey) + strlen(dictionary.Get(lastFixKey, ""))
}

		; 入力行を更新
        SendInput("{BS " bsLength "}" value)

        ; バッファと変換履歴を更新
		reCon_able := 0
        if (matchCount > 0){
			; 再マッチ時 (3 文字)
            inputBuffer := ""
	        matchCount := 0
			reCon_able := 1

			historyBuffer := SubStr(historyBuffer, 1, -bsLength)	; 変換区切りのスペースを入れたので↑から -1
			historyBuffer .= value . " "							; 区切りなしなら -bsLength+1 の方

		}else{
			; 初回マッチ (2 or 3 文字)
	    	matchCount += 1

			historyBuffer .= value . " "
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
	global reCon_able, inputBuffer, lastFixKey, lastFixKey2, dictionary, historyBuffer, reconBuffer 
	if (reCon_able == 1){
		follow_part := inputBuffer
		redo_part := SubStr(lastFixKey, (strLen(lastFixKey2) + 1)<1 ? (strLen(lastFixKey2) + 1)-1 : (strLen(lastFixKey2) + 1))
;		lastFixValue := dictionary[lastFixKey]
;		lastFixValue2 := dictionary[lastFixKey2]
		lastFixValue := dictionary.Get(lastFixKey, "")
		lastFixValue2 := dictionary.Get(lastFixKey2, "")		
		backcount := strLen(lastFixValue) + strLen(follow_part)

		; 入力行を更新: 元に戻した初期変換部分 ＋ 元に戻した 3 文字目の読み ＋ その後に入力された部分
		SendInput("{BS " backcount "}" lastFixValue2 "" redo_part "" follow_part)


		historyBuffer := SubStr(historyBuffer, 1, -strLen(lastFixValue)-1)	;  区切りなしなら -1 なし
		historyBuffer .= lastFixValue2 . " "
		reconBuffer .= lastFixValue . " "
		
		
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

;return

; 入力バッファをクリア
clearBuffer() {
	global inputBuffer, matchCount

	inputBuffer := ""
	matchCount := 0	
}

; 読みの検索
searchValue() {
	global dictionary

	target := A_Clipboard
	length := StrLen(target)
	if (length < 4){
	    for key, value in dictionary {
	    	if (target == value) {
				key_str := ""
				Loop Parse, key
				{
					key_str .= A_LoopField . " "
				}
				MsgBox("検索:  " target " `n読み:  " key_str " `n登録:  " value)
		    	break
	    	}
		}
	}
}

; 変換履歴をファイルへ出力
writeLogs() {
	global logEnable, historyBuffer, reconBuffer

	if (logEnable == 0){
		historyBuffer := ""		
		reconBuffer := ""
		return
	}

	if(historyBuffer){
		timeString := FormatTime(, "yyyy-MM-dd HH:mm:ss")
		str := timeString . "`n" . historyBuffer . "`n"
		WriteFile(str)
		historyBuffer := ""
	}

	if(reconBuffer){
		timeString := FormatTime(, "yyyy-MM-dd HH:mm:ss")
		str := "rc " . timeString . "`nrc " . reconBuffer . "`n"
		WriteFile(str)
		reconBuffer := ""
	}
}

; 単語の登録・修正
updateDictionary(){
	global dictionaryFile, FileSets, CurrentSet
    ; クリップボードから置換文字列を取得
    newEntry := A_Clipboard

    ; 入力フォーマットチェック (「英数=日本語」の形式)
    if (!RegExMatch(newEntry, "^[a-z0-9]+=[\p{Han}\p{Hiragana}\p{Katakana}]+$"))
    {
        msgResult := MsgBox("形式が正しくありません。 `n「英(小)字または数字=登録語句」の形式で入力してください。", "エラー", 48)
        return
    }

    ; ファイルパスを指定
    filePath := dictionaryFile

    ; ファイルの内容を読み込む
    fileContent := FileRead(filePath)

    ; 新しいエントリのキー (= の左側) を取得
    newKey := RegExReplace(newEntry, "=.*$")

    ; ファイル内で完全一致するエントリを検索
    if (RegExMatch(fileContent, "m)^" . newEntry . "$"))
    {
        msgResult := MsgBox("このエントリは既に登録されています。", "情報", 48)
        return
    }

    ; ファイル内でキーが一致するエントリを検索
    foundPos := RegExMatch(fileContent, "m)^" . newKey . "=.*$", &oldEntry)

    if (foundPos > 0)
    {
        ; 一致するエントリがある場合、置換の確認
		setname := FileSets[CurrentSet].name
        msgResult := MsgBox("次のエントリを修正します。よろしいですか？`n`n辞書セット: " setname " ( " dictionaryFile " ) `n変更前: " (oldEntry&&oldEntry[0]) "`n変更後: " newEntry, "確認", 4)
        if (msgResult = "No")
            return

        ; 置換を実行 (完全一致するものだけを置換)
        newContent := RegExReplace(fileContent, "m)^" . (oldEntry&&oldEntry[0]) . "$", newEntry)
    }
    else
    {
        ; 一致するエントリがない場合、追加の確認
		setname := FileSets[CurrentSet].name		
        msgResult := MsgBox("次のエントリを追加します。よろしいですか？`n`n辞書セット: " setname " ( " dictionaryFile " ) `n追加: " newEntry, "確認", 4)
        if (msgResult = "No")
            return

        ; ファイルの末尾に追加 (既存の内容の最後に改行があるか確認)

;		test := SubStr(fileContent, 0)
        if (SubStr(fileContent, -1) != "`n")
            newContent := fileContent . "`r`n" . newEntry
        else
            newContent := fileContent . newEntry
    }

    ; 新しい内容をファイルに書き込む、バックアップも作成
	timeString := FormatTime(, "yyyyMMdd-HHmmss")
	parts := StrSplit(filepath, "\")
	filename := parts[parts.Length]
	backupFilename := "dic_backup\" . timestring . "-" . filename
	Try {
	    FileCopy(filePath, backupFilename)
	    ErrorLevel := 0
	} Catch as Err {
	    ErrorLevel := Err.Extra
	}
    Try FileDelete(filePath)
    FileAppend(newContent, filePath, "UTF-8")

    msgResult := MsgBox("辞書ファイルを更新しました")

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
	global CurrentSet, iniFile

	writeLogs()
	IniWrite(CurrentSet, iniFile, "Currentset", "set")
	Reload()
}


; ドロップダウンリストの選択肢を作成
CreateDropDownList() {
	global CurrentSet, FileSets

	list := []
	Loop FileSets.Length
	{
		list.Push(A_Index . " " . FileSets[A_Index].name)
	}	
		return list
}
  
; GUI を作成する関数
CreateGui() {
	global CurrentSet

	gui2 := Gui()
	gui2.SetFont("s12")
	ddl_list := CreateDropDownList()
	myDDP := gui2.Add("DropDownList", "vSelectedSet", ddl_list)
	myDDP.OnEvent("Change", SwitchSetFromGui)
	myDDP.choose(ddl_list[CurrentSet])
	myBtn := gui2.Add("Button", "Default w80", "閉じる")
	myBtn.OnEvent("Click", (*)=> gui2.Destroy())
	gui2.OnEvent("Close", (*)=> gui2 := "")
	gui2.show
}

CreateGui_sonomama() {
    global CurrentSet
    oGui2 := Gui()
    
	oGui2.SetFont("s12")
	ogcDropDownListSelectedSet := oGui2.Add("DropDownList", "vSelectedSet", [CreateDropDownList()])
	ogcDropDownListSelectedSet.OnEvent("Change", SwitchSetFromGui.Bind("Normal"))
    ogcDropDownListSelectedSet.Choose(%CurrentSet%)
    oGui2.Show()
}

; カナ変換本体
;  文字列の先頭にあるアルファベット以外は無視する
ConvertKana(targetBuffer, hiraKata){
	global dictionaryKana

	head := RegExMatch(targetBuffer, "[a-zA-Z]")
	workingBuffer := SubStr(targetBuffer, (head)<1 ? (head)-1 : (head))

	kanaset := "hira"
	if (hiraKata == 2){
		kanaset := "kata"
	} 
	convertedKana := ""
	part := ""
	Loop{
		if (workingBuffer = "") {
				break
		} else {
			partCounter := 1
			Loop{
				if (partCounter > StrLen(workingBuffer) or workingBuffer = "") {
					convertedKana .= SubStr(workingBuffer, 1, 1)
					workingBuffer := SubStr(workingBuffer, 2)
					break
				}
				part := SubStr(workingBuffer, 1, partCounter)
				if (part)
					kana := dictionaryKana.Has(part) && dictionaryKana[part].Has(kanaset) ? dictionaryKana[part][kanaset] : ""
				if (kana != "") {
					convertedKana .= kana
					workingBuffer := SubStr(workingBuffer, (partCounter+1)<1 ? (partCounter+1)-1 : (partCounter+1))
					break
				}
				partCounter += 1
			}
		}
	}
	bslength := StrLen(targetBuffer)
	SendInput("{BS " bslength "}")
	SendInput(convertedKana)
	clearbuffer()
	UpdateDisplay()
}

; カナ変換(リアルタイム) 前方マッチで
;  文字列の先頭にあるアルファベット以外は無視する
ConvertKana_realTime(targetBuffer, currentBuffer, hiraKata){
	global dictionaryKana
	workingBuffer := targetBuffer

	kanaset := "hira"
	if (hiraKata == 2){
		kanaset := "kata"
	} 

	result := ""
	value := ""
	bufferLength := StrLen(workingBuffer)
	Loop
		{
			if (A_Index > bufferLength )
				break
	
			testValue := SubStr(workingBuffer, (A_Index)<1 ? (A_Index)-1 : (A_Index))
			value := dictionaryKana.Has(testValue) && dictionaryKana[testValue].Has(kanaset) ? dictionaryKana[testValue][kanaset] : ""

			if (value != "")
			{
				key := testValue
				break
			}
		}


	if (value != ""){
		bslength := StrLen(key)
		SendInput("{BS " bslength "}")
		SendInput(value)
		clearbuffer()
		updatedBuffer := SubStr(currentBuffer, 1, StrLen(currentBuffer) - bslength) . value
	} else {
		updatedBuffer := currentBuffer
	}
	UpdateDisplay()

	return updatedBuffer
}

; カナ変換 hiraKata=1: ひらがな or hiraKata=2: カタカナ
kanaConvert(hiraKata){
	global inputBuffer

	target := inputBuffer
	convertKana(target, hiraKata)
}

; 先頭の数字を追い出して変換
kickandConvert(){
	global inputBuffer

	head := RegExMatch(inputBuffer, "[a-z]")
	if (head > 1){
		targetBuffer := SubStr(inputBuffer, (head)<1 ? (head)-1 : (head))
		bslength := StrLen(targetBuffer)
		SendInput("{BS " bslength "}")

		clearBuffer()
		Loop Parse, targetBuffer
		{
			inputBuffer .= A_LoopField
			SendInput(A_LoopField)
			CheckAndConvert()
		}
		UpdateDisplay()
	}
}

; バッファの先頭 1 文字を追い出して変換
shrinkandConvert(){
	global inputBuffer

	targetBuffer := SubStr(inputBuffer, 2)
	bslength := StrLen(targetBuffer)
	SendInput("{BS " bslength "}")

	clearBuffer()
	Loop Parse, targetBuffer
	{
		inputBuffer .= A_LoopField
		SendInput(A_LoopField)
		CheckAndConvert()
	}
	UpdateDisplay()
}

; バッファの先頭 1 文字を削除して変換
deleteandConvert(){
	global inputBuffer

	targetBuffer := SubStr(inputBuffer, 2)
	bslength := StrLen(inputBuffer)
	SendInput("{BS " bslength "}")

	clearBuffer()
	Loop Parse, targetBuffer
	{
		inputBuffer .= A_LoopField
		SendInput(A_LoopField)
		CheckAndConvert()
	}
	UpdateDisplay()
}

; 起動時にTSVファイルを読み込んで配列にプッシュする
LoadJoyoKanji() {
	; Loop, Read を使ってテキストファイルを1行ずつ処理
	global dictionaryJyoyoKanji

    Loop Read, "dictionary-jyoyo-jinmei.tsv"
    {
        ; タブで分割
        parts := StrSplit(A_LoopReadLine, A_Tab)
        
        ; 配列にオブジェクトとして追加
        dictionaryJyoyoKanji.Push({ kanji: parts[1]
                     , kyuuji: parts[2]
                     , yomi: parts[3] })
    }
}

lookUpDict(keywards, &targetDict){
	; 入力文字をスペース区切りで配列にする（例: ["あい", "あわ"]）
	global dictionaryJyoyoKanji
	
	queryWords := StrSplit(keywards, A_Space)
		
	results := []

	; 常用漢字リストを全件検索（2000件程度なら一瞬で終わります）
	for index, data in dictionaryJyoyoKanji {
		isMatch := true
		paddedyomi :=  " " . data.yomi . " "
		; すべての検索ワードが含まれているかチェック (AND検索)
		for i, word in queryWords {
			if (word = "")
				continue
			
			; InStrで検索テキストの中にワードが含まれるか確認
			if (StrLen(word) = 1){
				yomiData := paddedyomi
				searchkey := " " . word . " "
			}else{
				yomiData := data.yomi
				searchkey := word
			}
;			if !InStr(yomiData, word) {
			if !InStr(yomiData, searchkey) {
					isMatch := false
				break ; 1つでも含まれていなければ次の漢字へ
			}
		}
		
		; すべてのワードにマッチしたら結果に追加
		if (isMatch) {
			results.Push(data.kanji)
			if (data.kyuuji != ""){
				results.Push(data.kyuuji)
			}
			if (results.Length > 10){
				results.Push("...")
				break
			}
		}
	}

	return results ; 絞り込まれた結果の配列を返す
}


showLookupResule(results) {
	global lookupPanel, lookupResults

	if(results = ""){
		lookupPanel.Hide()
	}else{
		lookupPanel["lookupDisplay"].Value := results
		GetCaretPos(&locx, &locy, &w, &h)
		locy += 30

		lowNum := lookupResults.Length
		if (lowNum > 30){
			lowNum := 30
		}
		pHeight := lowNum * 19 + 19
		lookupPanel.Show("NoActivate x" locx " y" locy " h" pHeight)
	}
}

confirmSuggest(selectedNumber){
	global lookupResults, yomiBuffer

	if (lookupResults.Has(selectedNumber) = 0){
		return 0
	}

	suggest := lookupResults[selectedNumber]

	bsLength := StrLen(yomiBuffer)
	SendInput("{BS " bslength "}")
	SendInput(suggest)

	return 1
}

IsConsonant(s) {
    return (StrLen(s) = 1) && InStr("BCDFGHJKLMNPQRSTVWXYZbcdfghjklmnpqrstvwxyz", s, true)
}

lookupRefference(){
	global yomiBuffer, inputBuffer, lookupPanel, lookingActive, dictionaryJyoyoKanji, lookupResults

	lookingActive := 1
;	if (yomiBuffer = "" or IsConsonant(yomiBuffer) = 1) {
	if (yomiBuffer = "") {
		lookupPanel.Hide()
		lookingActive := 0
		return 1
	}
	
	yomiBuffer := ConvertKana_realTime(inputBuffer, yomiBuffer, 1)
	lookupResults := lookUpDict(yomiBuffer, &dictionaryJyoyoKanji)
	A_Clipboard :=""
	resultsStrings := ""
	if (lookupResults.Length > 0) {
		for index, element in lookupResults{
			if (index > 30) {
				break
			}
				resultsStrings .= index . ": " . element . "`n"
		}
		Trim(resultsStrings, "`n")
	}
	
	showLookupResule(resultsStrings)
	lookingActive := 0
	
	return 1
}

lookupClear(){
	global lookupPanel, gui1, yomiBuffer, inputMode

	lookupPanel.Hide()
	gui1.BackColor := "E0E0E0"
	yomiBuffer := ""
	inputMode := "kanji"
}

changeLookupMode(){
	global inputMode, gui1, yomiBuffer

	if (inputMode == "kanji" or inputMode == "hira" or inputMode == "kata" or inputMode == "eisu") {
		inputMode := "lookup"
		gui1.BackColor := "80C080"
		yomiBuffer := ""
	} else if (inputMode == "lookup") {
		lookupClear()
	}
	clearBuffer()
	UpdateDisplay()
}

SwitchSetFromGui(GuiCtrlObj, Info) {
	selectedValue := GuiCtrlObj.Text
	index := SubStr(selectedValue, 1, 1)  ; "FileSetX" から数字部分を取り出す
	changefileset(index)	
	updateDisplay()

	return
}


; スクリプトの初期化時に ini ファイルを読み込む
GUI_init()

FileSets := LoadFileSets()
CurrentSet := LoadCurrent()
changefileset(CurrentSet)
LoadDictionary(CurrentSet)
LoadInifile()
LoadDictionaryKana()
LoadJoyoKanji()

UpdateDisplay()

#HotIf WinActive("ahk_group directinput", )

SetTimer(CheckHistory,moniterTimer) ; 60 秒間隔でチェック

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
{
	global inputBuffer, inputMode, yomiBuffer

	key1 := SubStr(A_ThisHotkey, 2)
	SendInput(key1)
	if (IME_GET() == 0){
		inputBackup := inputBuffer
		inputBuffer .= key1
		UpdateDisplay()
		if (inputMode == "kanji"){
			CheckAndConvert()
		} else if (inputMode == "lookup"){
			yomiBackup := yomiBuffer
			yomiBuffer .= key1
			result := lookupRefference()
		} else if (inputMode == "hira") {
			ConvertKana_realTime(inputBuffer, yomiBuffer, 1)
		} else if (inputMode == "kata") {
			ConvertKana_realTime(inputBuffer, yomiBuffer, 2)
		}
		UpdateDisplay()
	}
}

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
{ 
	global inputBuffer

	key1 := SubStr(A_ThisHotkey, 3)
	key := StrUpper(key1)
	SendInput(key)
	inputBuffer .= key
	UpdateDisplay()
}

$,::
{
	global inputBuffer, lastfixKey

	key1 := SubStr(A_ThisHotkey, 2)
	if (IME_GET() == 1){
		SendInput key1
	}else{
		if ( inputBuffer == "" or inputBuffer == lastfixKey){
			clearBuffer()
			SendInput(key1)
			inputBuffer .= key1
		} else {
			vpos := RegExMatch(inputBuffer, "[a-zA-Z0-9]")
			if (vpos == 1){
				clearBuffer()
				SendInput(key1)
				inputBuffer .= key1
			} else {
				keys := SubStr(inputBuffer, 2)

				bslength := StrLen(inputBuffer)
				SendInput("{BS " bslength "}" keys)
				clearBuffer()
			}
		} 
	}
	UpdateDisplay()
}



; 直前の変換の区切り位置を変更
^k::
^l::
{
		reConvert()
}

^$h::
{
	; 入力バッファから 1 文字削除 (画面内の未確定も同期)
;	#SuspendExempt

	global inputBuffer, yomiBuffer, inputMode, lastfixKey

	SendInput("{BS}")
	rinputBuffer := inputBuffer
	inputBuffer := SubStr(inputBuffer, 1, -1)
	if (inputMode = "lookup"){
		yomiBuffer := SubStr(yomiBuffer, 1, -1)
		lookupRefference()
	}
	
	if(rinputBuffer == lastFixKey){
		clearBuffer()
	}

	UpdateDisplay()
}

; 以下のキーでは入力バッファをクリア

$Enter:: ;HK68_Enter()
{
	if (inputMode != "lookup"){
		SendInput("{Enter}")
		clearBuffer()
		UpdateDisplay()
	}
}

$Space:: ;HK69_Space()
{
	global	inputMode, yomiBuffer

	SendInput("{Space}")
	clearBuffer()
	UpdateDisplay()

	if (inputMode == "lookup"){
		yomiBuffer .= " "
	}
}

!^Space:: ;HK70_Space()
{
	clearBuffer()
	UpdateDisplay()
}

$Tab:: ;HK71_Tab()
{
	SendInput("{Tab}")
	clearBuffer()
	UpdateDisplay()
}

+$Tab::
{
	SendInput("+{Tab}")
	clearBuffer()
	UpdateDisplay()
}

#SuspendExempt

; 変換システムを一時停止 
!F12:: ;HK72_F12()
{
	global gui1, active

	Suspend()
	active ^= 1
	if (active == 0) {
		gui1["textInputDisplay"].Value := "SUSPENDED"
		gui1.BackColor := "FF9900"
		clearBuffer()
	} else {
		gui1.BackColor := "E0E0E0"
		IME_SET(0)
		UpdateDisplay()
		clearBuffer()
	}
}

#SuspendExempt False

sc029::
{
	global imeStatus, gui1, f1mode, inputMode 
	; [半角/全角] キー
	if (inputMode == "lookup"){
		bslength := StrLen(yomiBuffer)
		SendInput("{BS " bsLength "}")
	}

;	inputMode := "kanji"

	ime_real_state := IME_GET()
	if (ime_real_state != imeStatus){
		imeStatus := ime_real_state
	}

	if (imeStatus == 0){
		lookupClear()
		gui1.BackColor := "a06040"
		gui1["textInputDisplay"].Opt("cblack")		
		IME_SET(1)
	}else{
		gui1.BackColor := "E0E0E0"
		IME_SET(0)
	}
	imeStatus ^= 1
	
	clearBuffer()
	UpdateDisplay()
}


; IME 入力モード固定
F5:: ;HK74_F5()
{
	global f1mode, gui1, imeStatus

	if (f1mode == 0){
		gui1.BackColor := "40C0C0"
	}
;	SendInput("^{F9}s")	;personal
	f1mode := 1
	imeStatus := 1
	clearBuffer()
	UpdateDisplay()
}

; 英数モード (ATOK 利用は廃止)
F1::
{
	global inputMode, gui1, yomiBuffer

	if (inputMode == "kanji" or inputMode == "hira" or inputMode == "kata") {
		inputMode := "eisu"
		gui1.BackColor := "606060"
		gui1["textInputDisplay"].Opt("cwhite")
	} else if (inputMode == "eisu") {
		inputMode := "kanji"
		gui1.BackColor := "E0E0E0"
		gui1["textInputDisplay"].Opt("cblack")
	}
	IME_SET(0)
	clearBuffer()
	UpdateDisplay()
}

; 漢字入力モード
^Space::
{
	global inputMode, gui1, yomiBuffer, imeStatus

	ime_real_state := IME_GET()
	if (ime_real_state != imeStatus){
		imeStatus := ime_real_state
	}

;	if (imeStatus == 1){
;		SendInput("^{Space}")
;		return
;	}
	if (inputMode == "lookup") {
		; 辞書参照中なら入力中の文字列を削除
		bslength := StrLen(yomiBuffer)
		if (bslength > 0){
			SendInput("{BS " bsLength "}")
		}
		lookupClear()
	}
	
	if (imeStatus == 1){
		IME_SET(0)
		imeStatus := 0
	}

	inputMode := "kanji"
	gui1.BackColor := "E0E0E0"
	gui1["textInputDisplay"].Opt("cblack")	

	IME_SET(0)
	clearBuffer()
	UpdateDisplay()
}


; 変換システムをリセット (IME をオフ)
!F11::
{
	#SuspendExempt
	IME_SET(0)
	writeandreload()
}

; 情報ウィンドウの表示/非表示を切替
^!p::
{
	toggleInfoPanel()
}

; 漢字の読みを検索 (カーソル位置から 1 文字戻って検索)
^g:: ;HK77_g()
{
	global active, gui1
	#SuspendExempt

	Suspend(false)

;	IME_SET(0)
	A_Clipboard := ""
	Send("+{LEFT}^c")
	Errorlevel := !ClipWait(1)
	if ErrorLevel
	{
	    return
	}
	searchValue()

	active := 1
	gui1.BackColor := "E0E0E0"
	UpdateDisplay()	
}

; 参照辞書を検索 (常用+人名+ユーザー)
^u::
F9::
!F9::
{
	changeLookupMode()
	IME_SET(0)
}

; ひらがな入力(リアルタイム)
F8::
^!o::
!m:: ;HK79_m()
{
	global inputMode, gui1, yomiBuffer

	if (inputMode == "kanji" or inputMode == "eisu" or inputMode == "kata") {
		inputMode := "hira"
		gui1.BackColor := "F0C080"
		gui1["textInputDisplay"].Opt("cblack")		
	} else if (inputMode == "hira") {
		inputMode := "kanji"
		gui1.BackColor := "E0E0E0"
	}
	IME_SET(0)
	clearBuffer()
	UpdateDisplay()
}

; カタカナ入力(リアルタイム)
F7::
^!i::
!n::
{
	global inputMode, gui1, yomiBuffer

	if (inputMode == "kanji" or inputMode == "eisu" or inputMode == "hira") {
		inputMode := "kata"
		gui1.BackColor := "F0E080"
		gui1["textInputDisplay"].Opt("cblack")
	} else if (inputMode == "kata") {
		inputMode := "kanji"
		gui1.BackColor := "E0E0E0"
	}
	IME_SET(0)
	clearBuffer()
	UpdateDisplay()
}

^$Enter::
{
	if (inputMode != "lookup"){
		key := "^{Enter}"
		SendInput(key)
			return
	}
	
	result := confirmSuggest(1)	
	if (result = 1){
		lookupClear()
		clearBuffer()
		UpdateDisplay()
	}
}

^$1::
^$2::
^$3::
^$4::
^$5::
^$6::
^$7::
^$8::
^$9::
{
; 補完候補を選択

	if (inputMode != "lookup"){
		key := "^" . SubStr(A_ThisHotkey, 3)
		SendInput key
			return
	}
	key := SubStr(A_ThisHotkey, 3)
	result := confirmSuggest(key)	
	if (result = 1){
		lookupClear()
		clearBuffer()
		UpdateDisplay()
	}	
}

^!$1::
^!$2::
^!$3::
^!$4::
^!$5::
^!$6::
^!$7::
^!$8::
^!$9::
{
; 補完候補を選択 (予備)

	if (inputMode != "lookup"){
		key := "^!" . SubStr(A_ThisHotkey, 4)
		SendInput key
			return
	}
	key := SubStr(A_ThisHotkey, 4)
	result := confirmSuggest(key)	
	if (result = 1){
		lookupClear()
		clearBuffer()
		UpdateDisplay()
	}	
}

; 変換履歴を出力 (タイマー処理)
CheckHistory()
{
	if (A_TimeIdlePhysical > 10000)	{
		writeLogs()
		clearBuffer()
		UpdateDisplay()
	}
}

  ; ドロップダウンリストの選択変更時の処理
;SwitchSet:
;SwitchSet()
;  return

; 辞書登録
^F8::
{
	updateDictionary()	
}

; 辞書ファイルセット 1 番
!F1::
{
	changefileset(1)
}

; 辞書ファイルセット 2 番
!F2::
{
	changefileset(2)
}

; 辞書ファイルセット選択ダイアログ
!F3::
{
	CreateGui()	
}

; ひらがな変換
!o::
{
	kanaConvert(1)
}

; カタカナ変換
!i::
{
	kanaConvert(2)
}

!e::
{
	kickandConvert()
}

!s::
{
	shrinkandConvert()
}

!d::
{
	deleteandConvert()
}

; 外部ライブラリ
; ==========================================================
; IMEv2.ahk
; Source: https://github.com/k-ayaki/IMEv2.ahk
; Author: kenichiro_ayaki

;-----------------------------------------------------------
; IMEの状態の取得
;   WinTitle="A"    対象Window
;   戻り値          1:ON / 0:OFF
;-----------------------------------------------------------
IME_GET(WinTitle:="A")  {
    hwnd := WinExist(WinTitle)
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        cbSize := 4+4+(PtrSize*6)+16
        stGTI := Buffer(cbSize,0)
        NumPut("DWORD", cbSize, stGTI.Ptr,0)   ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", "Uint",0, "Uint", stGTI.Ptr)
                 ? NumGet(stGTI.Ptr,8+PtrSize,"Uint") : hwnd
    }
    return DllCall("SendMessage"
          , "UInt", DllCall("imm32\ImmGetDefaultIMEWnd", "Uint",hwnd)
          , "UInt", 0x0283  ;Message : WM_IME_CONTROL
          ,  "Int", 0x0005  ;wParam  : IMC_GETOPENSTATUS
          ,  "Int", 0)      ;lParam  : 0
}

;-----------------------------------------------------------
; IMEの状態をセット
;   SetSts          1:ON / 0:OFF
;   WinTitle="A"    対象Window
;   戻り値          0:成功 / 0以外:失敗
;-----------------------------------------------------------
IME_SET(SetSts, WinTitle:="A")    {
    hwnd := WinExist(WinTitle)
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        cbSize := 4+4+(PtrSize*6)+16
        stGTI := Buffer(cbSize,0)
        NumPut("Uint", cbSize, stGTI.Ptr,0)   ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", "Uint",0, "Uint",stGTI.Ptr)
                 ? NumGet(stGTI.Ptr,8+PtrSize,"Uint") : hwnd
    }
    return DllCall("SendMessage"
          , "UInt", DllCall("imm32\ImmGetDefaultIMEWnd", "Uint",hwnd)
          , "UInt", 0x0283  ;Message : WM_IME_CONTROL
          ,  "Int", 0x006   ;wParam  : IMC_SETOPENSTATUS
          ,  "Int", SetSts) ;lParam  : 0 or 1
}

#HotIf !WinActive("ahk_group directinput")

#SuspendExempt
; 変換システムを一時停止 
!F12::
{
	global gui1, active

	Suspend()
	active ^= 1
	if (active == 0) {
		gui1["textInputDisplay"].Value := "SUSPENDED"
		gui1.BackColor := "FF9900"
		clearBuffer()
	} else {
		gui1.BackColor := "E0E0E0"
		UpdateDisplay()
	}
}
#SuspendExempt false

#HotIf
