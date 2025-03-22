; 漢字入力システム 最小構成 (direct-input-minimal.ahk)
;  Version: 0.1.0
;  動作確認: AutoHotKey 1.1.24.02
;  製作: kouie

#NoEnv
SetTitleMatchMode, 2

#SingleInstance, Force

global inputBuffer := ""    ; 変換用バッファ
global dictionary ={}       ; 辞書
global InputDisplay := ""
global active := 1

global matchCount := 0
global lastfixKey := ""
global lastfixKey2 := ""
global reCon_able := 0

; 辞書データの例 (サンプル)
; 読みと値を連想配列で格納
keys := ["tx", "xb", "gw", "qxk", "@tx", "@xb", "@gw", "x@"]
values := ["田中", "小林", "小川", "久子","田中", "小林", "小川", "久子" ]

Loop % keys.Length()
{
    dictionary[keys[A_Index]] := values[A_Index]
}

; 実際の辞書データはファイルから読み込む
LoadDictionary() {
    dictionaryFile := ".\dictionary-2only.txt"
;    dictionaryFile := ".\dictionary-local.txt"
;    dictionaryFile := ".\dictionary_kana.txt"
	FileRead, content, %dictionaryFile%
;	dictionary := {}
    Loop, Parse, content, `n, `r
    {
        if (A_LoopField = "")
            continue
        parts := StrSplit(A_LoopField, "=")
        if (parts.Length() == 2)
            dictionary[parts[1]] := parts[2]
    }
}

; 入力バッファの内容を変換
CheckAndConvert() {
    if (StrLen(inputBuffer) == 1){
    	return
    }
   
    value := dictionary[inputBuffer]
	key := inputBuffer

	if (value != "") {
        ; BS 回数の計算
		length := StrLen(key)
		if (matchCount == 0){
			bsLength := length
		} else {
			bsLength := length - strlen(lastFixKey) + strlen(dictionary[lastFixKey])
		}

		; 入力行を更新
        SendInput, {BS %bsLength%}%value%

        ; バッファと変換履歴を更新
		reCon_able := 0
        if (matchCount > 0){
			; 再マッチ時 (3 文字)
            inputBuffer := ""
	        matchCount := 0
			reCon_able := 1
		}else{
			; 初回マッチ (2 or 3 文字)
	    	matchCount += 1
	    }
        lastFixKey2 := lastFixKey
        lastFixKey := key

    }else{
    	if (matchCount == 1) {
    	    ; 3 文字のマッチなし、最後の 1 文字残してバッファをクリア
			inputBuffer := SubStr(inputBuffer, 0)
    		matchCount := 0
		}
	}
	UpdateDisplay()
}

; 直前の変換を対象に、区切り位置を(2文字目の後に)変更して再変換
reConvert_org(){
;	if (lastDispLength >= 0){
	if (reCon_able == 1){
		if ( StrLen(lastFixKey) > 2 ) {
			if (lastfixKey2 == SubStr(lastfixKey, 1, 2)) {
				follow_part := inputBuffer
				redo_part := SubStr(lastFixKey, strLen(lastFixKey2) + 1)
				lastFixValue := dictionary[lastFixKey]
				lastFixValue2 := dictionary[lastFixKey2]
				backcount := strLen(lastFixValue) + strLen(follow_part)

                ; 入力行を更新: 元に戻した初期変換部分 ＋ 元に戻した 3 文字目の読み ＋ その後に入力された部分
                SendInput, {BS %backcount%}%lastFixValue2%%redo_part%%follow_part%

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
	}
}

reConvert(){
	if (reCon_able == 1){
		follow_part := inputBuffer
		redo_part := SubStr(lastFixKey, strLen(lastFixKey2) + 1)
		lastFixValue := dictionary[lastFixKey]
		lastFixValue2 := dictionary[lastFixKey2]
		backcount := strLen(lastFixValue) + strLen(follow_part)

		; 入力行を更新: 元に戻した初期変換部分 ＋ 元に戻した 3 文字目の読み ＋ その後に入力された部分
		SendInput, {BS %backcount%}%lastFixValue2%%redo_part%%follow_part%

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
	inputBuffer := ""
	matchCount := 0	
	reCon_able := 0
}

; BS 入力時にバッファも 1 文字削除
; ※ IME 併用時にかな変換が成立している場合は削除する文字の再カウントが必要 (ここでは未対応)
backspaceBuffer(){
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
	Gui, 1:New, +AlwaysOnTop +ToolWindow -Caption
	Gui, 1:Font, s12
	Gui, 1:Add, Text, vInputDisplay w200
	Gui, 1:Show, NoActivate x0 y0
}

; 情報ウィンドウを更新
UpdateDisplay() {
    GuiControl, 1:, InputDisplay, %reCon_able% %matchCount% | %lastfixKey% - %inputBuffer% 
}

LoadDictionary()
GUI_init()
UpdateDisplay()

; キーマップ定義
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
	key1 := SubStr(A_ThisHotkey, 2)
	SendInput, %key1%
	inputBuffer .= key1     ; 入力文字をバッファに追加
    UpdateDisplay()
	CheckAndConvert()
return

; 1 文字削除
$BS::
^$h::
    Suspend, Permit

	SendInput, {BS}
	backspaceBuffer()
return

; カーソル移動系はバッファをクリアする
$Enter::
$Space::
$Tab::
$Esc::
    key := SubStr(A_ThisHotkey, 2)
    SendInput, {%key%}
    clearBuffer()
    UpdateDisplay()    
Return

; 再変換
^k::
^l::
	reConvert()
return

; 変換システムを一時停止 
!F12::
^q::
    Suspend
    active ^= 1
	if (active == 0) {
		clearBuffer()
		GuiControl, 1:, InputDisplay, SUSPENDED
		Gui, 1:Color, FF9900
	} else {
		Gui, 1:Color, E0E0E0
		UpdateDisplay()
	}
return

; 変換システムをリセット
!F11::
	Suspend, Permit
    Reload
return
