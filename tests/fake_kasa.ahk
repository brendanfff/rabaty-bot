; Udawany program kasowy - zapisuje kazdy odebrany klawisz do kasa_log.txt
#NoEnv
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
global Log := ""
FileDelete, kasa_log.txt
Gui, +AlwaysOnTop
Gui, Add, Edit, w400 h300 Multi WantReturn
Gui, Show, w420 h320, Kasa TEST
OnMessage(0x100, "KlawiszWcisniety")
OnMessage(0x102, "ZnakWpisany")
SetTimer, ZapiszLog, 200
return

ZapiszLog:
FileDelete, kasa_log.txt
FileAppend, %Log%, kasa_log.txt
return

GuiClose:
ExitApp

KlawiszWcisniety(wParam, lParam, msg, hwnd)
{
    if (wParam = 0x0D)
        Log .= "{Enter}"
    else if (wParam = 0x70)
        Log .= "{F1}"
}

ZnakWpisany(wParam, lParam, msg, hwnd)
{
    if (wParam >= 32)
        Log .= Chr(wParam)
}
