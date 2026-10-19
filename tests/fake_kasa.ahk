; Udawany program kasowy: okno firm -> F10 lista kart -> F4 modyfikacja karty -> F10 zapis / Esc
#NoEnv
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
SetBatchLines, -1
global Karty := {}
for f, r in {"k1001": [5, 5, 5], "k1002": [7], "k1003": [20, 3], "k1004": [1, 2, 3, 4], "k1005": [1, 2, 3], "k1006": [1, 10, 0, 4], "k1007": [[10, "PB", ""], [10, "", ""], [20, "PB 12345", ""], [10, "", ". pb ."]], "k1008": [10, 30]}
{
    Karty[f] := []
    for i, v in r
    {
        if IsObject(v)
            Karty[f].Push({"n": "K" SubStr(f, 2) "-" i, "r": v[1], "rej": v[2], "nazw": v[3]})
        else
            Karty[f].Push({"n": "K" SubStr(f, 2) "-" i, "r": v, "rej": "", "nazw": ""})
    }
}
global Firma := "", Sel := 1, Zapisy := 0, Zdarzenia := ""
global FirmyHwnd := 0, ListaHwnd := 0, KartaHwnd := 0

Gui, Firmy:New, +HwndFirmyHwnd, Kasa TEST - Firmy
Gui, Firmy:Add, Edit, vSzukaj w300
Gui, Firmy:Show, x100 y100 w320 h60
OnMessage(0x100, "Klawisz")
OnMessage(0x104, "Klawisz")
OnMessage(0x105, "SysUp")
SetTimer, ZapiszStan, 150
return

ZapiszStan:
s := ""
for id, k in Karty
{
    r := ""
    for i, v in k
        r .= (i > 1 ? "," : "") v.r
    s .= (s == "" ? "" : "|") SubStr(id, 2) "=" r
}
WinGetTitle, akt, A
s .= "`nZapisy=" Zapisy "`nLista=" (ListaHwnd ? 1 : 0) "`nKarta=" (KartaHwnd ? 1 : 0) "`nAktywne=" akt "`nZdarzenia=" Zdarzenia
FileDelete, kasa_stan.txt
FileAppend, %s%, kasa_stan.txt
return

ElementyListy()
{
    t := ""
    for i, v in Karty["k" Firma]
        t .= "|" v.n "  rabat " v.r
    return t
}

OtworzListe:
Zdarzenia .= "[lista " Firma "] "
Gui, Lista:New, +HwndListaHwnd, Lista kart
Gui, Lista:Add, ListBox, vLB AltSubmit w300 h120, % SubStr(ElementyListy(), 2)
GuiControl, Lista:Choose, LB, 1
Gui, Lista:Add, Edit, vFiltr w300
Gui, Lista:Show, x150 y150 w320 h170
GuiControl, Lista:Focus, LB
return

OtworzKarte:
GuiControlGet, Sel, Lista:, LB
Gui, Karta:New, +HwndKartaHwnd, Modyfikacja karty
Gui, Karta:Add, Edit, w200 ReadOnly, % Karty["k" Firma][Sel].n
Gui, Karta:Add, Edit, w200, % Karty["k" Firma][Sel].nazw
Gui, Karta:Add, Edit, w200, 1000
Gui, Karta:Add, Edit, w200, ON
Gui, Karta:Add, Edit, w200, % Karty["k" Firma][Sel].rej
Gui, Karta:Add, Edit, w200 vRabat, % Karty["k" Firma][Sel].r
Gui, Karta:Add, Edit, w200, T
Gui, Karta:Show, x200 y200 w220 h260
return

ZamknijKarte(zapisz)
{
    if (zapisz)
    {
        GuiControlGet, val, Karta:, Rabat
        Karty["k" Firma][Sel].r := val
        Zapisy++
    }
    Gui, Karta:Destroy
    KartaHwnd := 0
    GuiControl, Lista:, LB, % ElementyListy()
    GuiControl, Lista:Choose, LB, % ((zapisz && Firma = "1004") || Firma = "1006") ? 1 : Sel
    WinActivate, ahk_id %ListaHwnd%
    if (zapisz && Firma = "1005")   ; po zapisie kursor ucieka do pola filtra
        GuiControl, Lista:Focus, Filtr
    else
        GuiControl, Lista:Focus, LB
}

Klawisz(wParam, lParam, msg, hwnd)
{
    top := DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr")
    if (wParam != 0x10)
        Zdarzenia .= Format("{:X}", wParam) (top = FirmyHwnd ? "F" : top = ListaHwnd ? "L" : top = KartaHwnd ? "K" : "?") " "
    if (top = FirmyHwnd)
    {
        if (wParam = 0x0D)
        {
            GuiControlGet, Firma, Firmy:, Szukaj
            GuiControl, Firmy:, Szukaj
            Zdarzenia .= "[firma=" Firma "] "
            return 0
        }
        if (wParam = 0x79)
        {
            if Karty.HasKey("k" Firma)
                SetTimer, OtworzListe, -400
            return 0
        }
    }
    else if (top = ListaHwnd && !KartaHwnd)
    {
        if (wParam = 0x73)
        {
            SetTimer, OtworzKarte, -400
            return 0
        }
        if (wParam = 0x1B)
        {
            Gui, Lista:Destroy
            ListaHwnd := 0
            WinActivate, ahk_id %FirmyHwnd%
            return 0
        }
        if (wParam = 0x79)
            return 0
    }
    else if (top = KartaHwnd)
    {
        if (wParam = 0x79)
        {
            ZamknijKarte(true)
            return 0
        }
        if (wParam = 0x1B)
        {
            ZamknijKarte(false)
            return 0
        }
    }
}

SysUp(wParam, lParam, msg, hwnd)
{
    if (wParam = 0x79)
        return 0
}
