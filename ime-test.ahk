#Requires AutoHotkey v2.0	


global hIMC_g := 0
; ==========================================================
; 現在のアクティブウィンドウでIMEが入力中（未確定文字がある）かどうかを判定する関数
; 戻り値: 未確定文字があれば true、なければ false
; ==========================================================
IsIMEComposing() {
	global hIMC_g

    ; 1. 最前面のトップレベルウィンドウを取得
    hWnd := DllCall("GetForegroundWindow", "Ptr")
    if (!hWnd)
        return false

    ; 2. スレッドIDの取得
    TargetThreadID := DllCall("GetWindowThreadProcessId", "Ptr", hWnd, "Ptr", 0)
    CurrentThreadID := DllCall("GetCurrentThreadId", "UInt")

    ; 3. AHKのスレッドを、対象ウィンドウのスレッドに一時的に結合
    isAttached := false
    if (TargetThreadID != CurrentThreadID) {
        ; AttachThreadInput(idAttach, idAttachTo, fAttach)
        isAttached := DllCall("AttachThreadInput", "UInt", CurrentThreadID, "UInt", TargetThreadID, "Int", 1)
    }

    ; 4. フォーカスのあるコントロールのハンドルを取得
    cbSize := A_PtrSize == 8 ? 72 : 48
    guiThreadInfo := Buffer(cbSize, 0)
    NumPut("UInt", cbSize, guiThreadInfo)

    hwndFocus := hWnd
    if DllCall("GetGUIThreadInfo", "UInt", TargetThreadID, "Ptr", guiThreadInfo) {
        hwndFocus_temp := NumGet(guiThreadInfo, 8 + A_PtrSize, "Ptr")
        if (hwndFocus_temp)
            hwndFocus := hwndFocus_temp
    }

    ; 5. 入力コンテキストの取得
    hIMC := DllCall("imm32\ImmGetContext", "Ptr", hwndFocus, "Ptr")
    hIMC_g := hIMC
	
    size := 0
    if (hIMC) {
        ; 未確定文字列の長さを取得
        size := DllCall("imm32\ImmGetCompositionStringW", "Ptr", hIMC, "UInt", 0x0008, "Ptr", 0, "UInt", 0, "Int")
        
        ; 入力コンテキストの解放 (必須)
        DllCall("imm32\ImmReleaseContext", "Ptr", hwndFocus, "Ptr", hIMC)
    }

    ; 6. スレッドの結合を解除 (これを忘れるとキー入力がおかしくなるため必須)
    if (isAttached) {
        DllCall("AttachThreadInput", "UInt", CurrentThreadID, "UInt", TargetThreadID, "Int", 0)
    }

    return (size > 0)
}

global hIMC_g


; 例: Ctrl + Shift + J で IME を安全にオフにする
!+j::
^+j::
 {
	global hIMC_g

	ret := IsIMEComposing()
	MsgBox(ret . " " . hIMC_g)
    if ret {
        ; 未確定の文字がある場合のみ、ESCを送信してキャンセル
        Send("{Esc}")
        Sleep(50) ; キャンセルが反映されるまで少し待機（環境に応じて調整）
    }
    
    ; ここで IME_SET() などを呼び出す
    IME_SET(0)
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
