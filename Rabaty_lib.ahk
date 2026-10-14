; ===== Logika programu Rabaty (wspolna dla programu i testow) =====

; Ustawienia (czasy w ms). Mozna je zmienic w pliku Rabaty.ini obok programu.
global Ust := ""

InitUst()
{
    if !IsObject(Ust)
        Ust := {"Tempo": 1.0, "IloscTab": 5, "PoEnter": 700, "PoListaKart": 1000, "PoF4": 1000, "PoTab": 150, "PoWpisaniu": 300, "PoZapisie": 1000, "PoStrzalce": 400, "PoEsc": 800}
}

WczytajUstawienia(Plik)
{
    InitUst()
    if !FileExist(Plik)
    {
        t := "; Ustawienia programu Rabaty. Czasy w milisekundach (1000 = 1 sekunda).`r`n"
        t .= "; Jesli kasa nie nadaza - zwieksz Tempo, np. 1.5 albo 2 (wszystkie czasy x Tempo).`r`n"
        t .= "[Ustawienia]`r`n"
        for k, v in Ust
            t .= k "=" v "`r`n"
        FileAppend, %t%, %Plik%
        return
    }
    for k, v in Ust
    {
        IniRead, val, %Plik%, Ustawienia, %k%, %v%
        val := Trim(val)
        if val is number
            Ust[k] := val + 0
    }
}

Czekaj(Klucz)
{
    InitUst()
    Sleep, % Round(Ust[Klucz] * Ust.Tempo)
}

; Wczytuje plik z rabatami.
; Format: 1. linia = cena na slupie, kolejne: ID;CENA;RABAT[;LICZBA_KART]
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
        fKarty := (Fields.Length() >= 4) ? Trim(Fields[4], " `t") : ""
        if fKarty is not integer
            fKarty := 0
        if (fID == "" || fRabat == "")
            continue
        FirmList.Push({"id": fID, "cena": fCena, "rabat": fRabat, "karty": fKarty + 0})
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

Aktywuj(Hwnd)
{
    if (Hwnd && !WinActive("ahk_id " Hwnd))
    {
        WinActivate, ahk_id %Hwnd%
        WinWaitActive, ahk_id %Hwnd%,, 2
        Sleep, 150
    }
}

; Wprowadza rabat dla jednej firmy:
; ID, Enter, F10 (lista kart), dla kazdej karty: F4, Tab x5, rabat, F10 (zapis), strzalka w dol; na koniec Esc.
; LiczbaKart > 0 - tyle kart automatycznie; 0 - pyta po kazdej karcie (PytajFn).
; Zwraca: "ok" albo "stop".
WprowadzFirme(Hwnd, curID, curRabat, LiczbaKart, PytajFn)
{
    InitUst()
    Aktywuj(Hwnd)
    Send, {Raw}%curID%
    Czekaj("PoWpisaniu")
    Send, {Enter}
    Czekaj("PoEnter")

    Send, {F10}                ; lista kart
    Czekaj("PoListaKart")

    Nr := 0
    Loop
    {
        Nr++
        Send, {F4}             ; modyfikacja karty
        Czekaj("PoF4")
        Loop, % Ust.IloscTab
        {
            Send, {Tab}
            Czekaj("PoTab")
        }
        Send, {End}+{Home}     ; zaznacz stara wartosc rabatu
        Send, {Raw}%curRabat%
        Czekaj("PoWpisaniu")
        Send, {F10}            ; zapis karty
        Czekaj("PoZapisie")

        if (LiczbaKart > 0)
        {
            if (Nr >= LiczbaKart)
                break
            Odp := "tak"
        }
        else
        {
            WinGet, ListaHwnd, ID, A
            Odp := PytajFn.Call(curID, Nr)
            if (Odp == "stop")
                return "stop"
            Aktywuj(ListaHwnd)
            if (Odp != "tak")
                break
        }
        Send, {Down}           ; nastepna karta
        Czekaj("PoStrzalce")
    }

    Send, {Esc}                ; wyjscie z listy kart
    Czekaj("PoEsc")
    return "ok"
}
