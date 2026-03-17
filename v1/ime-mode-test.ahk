; IME 動作モード判定ツール (ime-mode-test.ahk)
;  Version: 1.0.0
;  動作確認: AutoHotKey 1.1.24.02
;  製作: kouie

#NoEnv
#SingleInstance, Force

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

;-------------------------------------------------------
; IME 入力モード取得
;   WinTitle="A"    対象Window
;   戻り値          入力モード
;--------------------------------------------------------
IME_GetConvMode(WinTitle="A")   {
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
          ,  Int, 0x001   ;wParam  : IMC_GETCONVERSIONMODE
          ,  Int, 0)      ;lParam  : 0
}

;===========================================================================
; IME 変換モード (ATOKはver.16で調査、バージョンで多少違うかも)

;   MS-IME  0:無変換 / 1:人名/地名                    / 8:一般    /16:話し言葉
;   ATOK系  0:固定   / 1:複合語              / 4:自動 / 8:連文節
;   WXG              / 1:複合語  / 2:無変換  / 4:自動 / 8:連文節
;   SKK系            / 1:ノーマル (他のモードは存在しない？)
;   Googleβ                                          / 8:ノーマル
;------------------------------------------------------------------
; IME 変換モード取得
;   WinTitle="A"    対象Window
;   戻り値 MS-IME  0:無変換 1:人名/地名               8:一般    16:話し言葉
;          ATOK系  0:固定   1:複合語           4:自動 8:連文節
;          WXG4             1:複合語  2:無変換 4:自動 8:連文節
;------------------------------------------------------------------
IME_GetSentenceMode(WinTitle="A")   {
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
          ,  Int, 0x003   ;wParam  : IMC_GETSENTENCEMODE
          ,  Int, 0)      ;lParam  : 0
}

result := ""

CreateGui() {
    Gui, 1:New, +AlwaysOnTop, IME mode checker 
    Gui, 1:Font, s11
    Gui, 1:Add, Edit,, IME の状態・モードを判定します
    Gui, 1:Add, Text, vresult , IME 状態: `n入力ﾓｰﾄﾞ (ConvMode): -`n変換ﾓｰﾄﾞ (SentenceMode): -
    Gui, 1:Show
  }

global stat := ["オフ", "オン"]
CreateGui()
SetTimer, update, 1000 ; 1 秒間隔でチェック
return

update:
  conv := IME_GetConvMode()
  sent := IME_GetSentenceMode()
  ime := IME_GET() + 1
  imeStatus := stat[ime]
  GuiControl, 1:, result, IME 状態: %imeStatus% `n入力ﾓｰﾄﾞ (ConvMode): %conv% `n変換ﾓｰﾄﾞ (SentenceMode): %sent%
Return

GuiClose:
ExitApp
