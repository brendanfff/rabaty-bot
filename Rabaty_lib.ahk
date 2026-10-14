; ===== Logika programu Rabaty (wspolna dla programu i testow) =====

; Wczytuje plik z rabatami.
; Format: 1. linia = cena na slupie, kolejne linie = ID;CENA;RABAT
; Zwraca true/false, bledy w zmiennej Blad.
WczytajRabaty(Sciezka, ByRef CenaSlupa, ByRef FirmList, ByRef Blad)
{
    CenaSlupa := ""
    FirmList := []
    Blad := ""

    if !FileExist(Sciezka)
    {
        Blad := "Nie znaleziono pliku:`n" Sciezka
        return false
    }

    FileRead, FileContent, %Sciezka%
    if ErrorLevel
    {
        Blad := "Nie mozna odczytac pliku:`n" Sciezka
        return false
    }

    Lines := StrSplit(FileContent, "`n", "`r")
    if (Lines.Length() < 2)
    {
        Blad := "Plik jest pusty lub niepoprawny (min. 2 linie: cena slupa + firmy)."
        return false
    }

    CenaSlupa := Trim(Lines[1], " `t")

    Loop, % Lines.Length()
    {
        if (A_Index == 1)
            continue
        CurrentLine := Trim(Lines[A_Index], " `t")
        if (CurrentLine == "")
            continue
        Fields := StrSplit(CurrentLine, ";")
        if (Fields.Length() < 3)
            continue
        fID := Trim(Fields[1], " `t")
        fCena := Trim(Fields[2], " `t")
        fRabat := Trim(Fields[3], " `t")
        if (fID == "" || fRabat == "")
            continue
        FirmList.Push({"id": fID, "cena": fCena, "rabat": fRabat})
    }

    if (FirmList.Length() == 0)
    {
        Blad := "Brak poprawnych wierszy z firmami (format: ID;CENA;RABAT)."
        return false
    }
    return true
}

PoliczDziesiatki(FirmList)
{
    Count := 0
    for i, item in FirmList
        if (item.rabat = "10")
            Count++
    return Count
}

; Wpisuje jedna firme do okna programu kasowego (Hwnd).
WprowadzFirme(Hwnd, curID, curRabat)
{
    if (Hwnd)
    {
        WinActivate, ahk_id %Hwnd%
        WinWaitActive, ahk_id %Hwnd%,, 2
    }
    Sleep, 150

    Send, {Raw}%curID%
    Sleep, 200
    Send, {Enter}
    Sleep, 400

    Send, {F1}
    Sleep, 300

    Send, {Raw}%curRabat%
    Sleep, 200
    Send, {Enter}
    Sleep, 300
    Send, {Enter}
    Sleep, 400
}
