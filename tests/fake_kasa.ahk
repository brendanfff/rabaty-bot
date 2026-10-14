; Udawany program kasowy - zapisuje kazdy odebrany klawisz do kasa_log.txt
#NoEnv
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
global Log := ""
FileDelete, kasa_log.txt
Gui, +AlwaysOnTop
Gui, Add, Edit, w400 h300 Multi WantReturn WantTab
Gui, Show, w420 h320, Kasa TEST
OnMessage(0x100, "Klawisz")   ; WM_KEYDOWN
OnMessage(0x104, "Klawisz")   ; WM_SYSKEYDOWN (F10)
OnMessage(0x105, "SysUp")     ; WM_SYSKEYUP - blokada menu po F10
OnMessage(0x102, "Znak")      ; WM_CHAR
SetTimer, ZapiszLog, 200
return

ZapiszLog:
FileDelete, kasa_log.txt
FileAppend, %Log%, kasa_log.txt
return

GuiClose:
ExitApp

Klawisz(wParam, lParam, msg, hwnd)
{
    static nazwy := {0x0D: "{Enter}", 0x09: "{Tab}", 0x1B: "{Esc}", 0x28: "{Down}", 0x24: "{Home}", 0x23: "{End}", 0x73: "{F4}", 0x79: "{F10}", 0x70: "{F1}"}
    if nazwy.HasKey(wParam)
        Log .= nazwy[wParam]
    if (wParam = 0x79 || wParam = 0x09)
        return 0
}

SysUp(wParam, lParam, msg, hwnd)
{
    if (wParam = 0x79)
        return 0
}

Znak(wParam, lParam, msg, hwnd)
{
    if (wParam >= 32)
        Log .= Chr(wParam)
}
