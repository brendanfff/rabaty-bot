; ===== Logika programu Rabaty (wspolna dla programu i testow) =====
global Ust := ""
global OstatniBlad := ""
global LiczbaZmienionych := 0
global LogPlik := ""

Log(t)
{
    if (LogPlik == "")
        return
    FormatTime, cz,, HH:mm:ss
    FileAppend, % cz "  " t "`r`n", %LogPlik%
}

InitUst()
{
    if IsObject(Ust)
        return
    Ust := {}
    Ust.Tempo := 1.0          ; mnoznik wszystkich czasow
    Ust.IloscTab := 5         ; ile Tabow do pola rabatu (gdy brak kalibracji)
    Ust.PoleRabatu := ""      ; ClassNN pola rabatu (z kalibracji Ctrl+K), np. TEdit3
    Ust.OknoKarty := ""       ; okno modyfikacji karty (z kalibracji), np. ahk_class TFormKarta
    Ust.MaxCzekanie := 5000   ; max czekanie na pojawienie/zamkniecie okna
    Ust.MaxKart := 60         ; bezpiecznik: max kart na firme
    Ust.MaxOtwarc := 400      ; bezpiecznik: max otwarc okna karty na firme
    Ust.PoEnter := 700
    Ust.PoOknie := 300        ; dodatkowa chwila po pojawieniu sie okna
    Ust.PoTab := 120
    Ust.PoWpisaniu := 250
    Ust.PoStrzalce := 400
    Ust.PoEsc := 600
}

WczytajUstawienia(Plik)
{
    InitUst()
    if !FileExist(Plik)
    {
        ZapiszUstawienia(Plik)
        return
    }
    for k, v in Ust
    {
        IniRead, val, %Plik%, Ustawienia, %k%, %A_Space%
        val := Trim(val)
        if (val == "")
            continue
        if v is number
        {
            if val is number
                Ust[k] := val + 0
        }
        else
            Ust[k] := val
    }
}

ZapiszUstawienia(Plik)
{
    InitUst()
    FileDelete, %Plik%
    t := "; Ustawienia programu Rabaty. Czasy w milisekundach (1000 = 1 sekunda).`r`n"
    t .= "; Jesli kasa nie nadaza - zwieksz Tempo, np. 1.5 albo 2.`r`n"
    t .= "; PoleRabatu i OknoKarty ustawia kalibracja (Ctrl+K w oknie modyfikacji karty).`r`n"
    t .= "[Ustawienia]`r`n"
    for k, v in Ust
        t .= k "=" v "`r`n"
    FileAppend, %t%, %Plik%
}

Czekaj(Klucz)
{
    InitUst()
    Sleep, % Round(Ust[Klucz] * Ust.Tempo)
}

MaxCzas()
{
    return Round(Ust.MaxCzekanie * Ust.Tempo)
}

; Czeka az aktywne bedzie INNE okno niz Poprzednie (opcjonalnie pasujace do Kryterium).
CzekajNaNoweOkno(Poprzednie, Kryterium := "")
{
    Start := A_TickCount
    Loop
    {
        WinGet, h, ID, A
        if (h && h != Poprzednie && (Kryterium == "" || WinActive(Kryterium " ahk_id " h)))
        {
            Czekaj("PoOknie")
            return h
        }
        if (A_TickCount - Start > MaxCzas())
            return 0
        Sleep, 50
    }
}

CzekajNaZamkniecie(Hwnd)
{
    WinWaitClose, ahk_id %Hwnd%,, % MaxCzas() / 1000
    if ErrorLevel
        return false
    Czekaj("PoOknie")
    return true
}

; Wczytuje plik z rabatami. 1. linia = cena na slupie, kolejne: ID;CENA;RABAT
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

Aktywuj(Hwnd)
{
    if (Hwnd && !WinActive("ahk_id " Hwnd))
    {
        WinActivate, ahk_id %Hwnd%
        WinWaitActive, ahk_id %Hwnd%,, 2
        Sleep, 150
    }
}

TakiSamRabat(a, b)
{
    a := StrReplace(Trim(a), ",", ".")
    b := StrReplace(Trim(b), ",", ".")
    if a is number
        if b is number
            return (a + 0 == b + 0)
    return (a == b)
}

; Ustawia kursor w polu rabatu w oknie karty i zwraca jego obecna wartosc.
PrzejdzDoPolaRabatu(Dlg, ByRef Pole)
{
    Pole := ""
    if (Ust.PoleRabatu != "")
    {
        ControlFocus, % Ust.PoleRabatu, ahk_id %Dlg%
        if !ErrorLevel
            Pole := Ust.PoleRabatu
    }
    if (Pole == "")
    {
        Loop, % Ust.IloscTab
        {
            Send, {Tab}
            Czekaj("PoTab")
        }
        ControlGetFocus, Pole, ahk_id %Dlg%
    }
    Wartosc := ""
    if (Pole != "")
        ControlGetText, Wartosc, %Pole%, ahk_id %Dlg%
    if (Wartosc == "")
        Wartosc := SkopiujZaznaczone()
    return Wartosc
}

; Dane karty (wszystkie pola okna OPROCZ pola rabatu) - rozpoznaje te sama karte.
IdentyfikatorKarty(Dlg, Pole)
{
    WinGet, lista, ControlList, ahk_id %Dlg%
    id := ""
    Loop, Parse, lista, `n
    {
        if (A_LoopField == Pole)
            continue
        ControlGetText, tx, %A_LoopField%, ahk_id %Dlg%
        if (tx != "")
            id .= A_LoopField "=" tx "|"
    }
    return id
}

SkopiujZaznaczone()
{
    Zapas := ClipboardAll
    Clipboard := ""
    Send, {End}+{Home}^c
    ClipWait, 0.5
    w := Clipboard
    Clipboard := Zapas
    Zapas := ""
    return w
}

; Wprowadza rabat dla wszystkich kart jednej firmy.
; ID, Enter, F10 (lista kart), dla kazdej karty: F4, pole rabatu, rabat, F10 (zapis), strzalka w dol.
; Karty juz zmienione (rozpoznane po danych karty) sa pomijane - dziala tez, gdy lista po zapisie wraca na gore.
; Koniec listy = strzalka w dol nie zmienia karty (dwa razy z rzedu ta sama karta).
; Zwraca liczbe zmienionych kart albo -1 przy bledzie (opis w OstatniBlad).
WprowadzFirme(FirmaHwnd, curID, curRabat)
{
    InitUst()
    OstatniBlad := ""
    Log("=== Firma " curID ", rabat " curRabat)
    Aktywuj(FirmaHwnd)
    if !FirmaHwnd
        WinGet, FirmaHwnd, ID, A

    Send, {Raw}%curID%
    Czekaj("PoWpisaniu")
    Send, {Enter}
    Czekaj("PoEnter")

    Send, {F10}                         ; lista kart
    ListaHwnd := CzekajNaNoweOkno(FirmaHwnd)
    if !ListaHwnd
    {
        OstatniBlad := "Po F10 nie otworzylo sie okno listy kart (firma " curID ").`nSprawdz, czy ID firmy jest poprawne."
        Log("BLAD: " OstatniBlad)
        return -1
    }
    WinGetTitle, t, ahk_id %ListaHwnd%
    Log("Lista kart: " t)

    Zmienione := 0
    Zapisane := {}
    OstatnioPominieta := ""
    Loop
    {
        if (A_Index > Ust.MaxOtwarc || Zmienione >= Ust.MaxKart)
        {
            OstatniBlad := "Przekroczono limit kart dla firmy " curID "."
            Log("BLAD: " OstatniBlad)
            return -1
        }
        Aktywuj(ListaHwnd)
        Send, {F4}                      ; modyfikacja karty
        Dlg := CzekajNaNoweOkno(ListaHwnd, Ust.OknoKarty)
        if !Dlg
        {
            OstatniBlad := "Po F4 nie otworzylo sie okno modyfikacji karty (firma " curID ", zmienione karty: " Zmienione ")."
            Log("BLAD: " OstatniBlad)
            return -1
        }

        Wartosc := PrzejdzDoPolaRabatu(Dlg, Pole)
        Karta := IdentyfikatorKarty(Dlg, Pole)
        Log("Otwarta karta: [" Karta "] pole " Pole " = " Wartosc)

        Juz := false
        if (Karta != "")
            Juz := Zapisane.HasKey(Karta)
        else
            Juz := (Zmienione > 0 && TakiSamRabat(Wartosc, curRabat))

        if (Juz)
        {
            ; Ta karta jest juz zrobiona. Jesli to ta sama co przed chwila - strzalka nie przesunela = koniec listy.
            Koniec := (Karta == "" || Karta == OstatnioPominieta)
            Send, {Esc}
            if !CzekajNaZamkniecie(Dlg)
            {
                OstatniBlad := "Nie zamknelo sie okno karty po Esc (firma " curID ")."
                Log("BLAD: " OstatniBlad)
                return -1
            }
            if (Koniec)
            {
                Log("Koniec listy kart.")
                break
            }
            Log("Karta juz zmieniona - pomijam i ide nizej.")
            OstatnioPominieta := Karta
            Aktywuj(ListaHwnd)
            Send, {Down}
            Czekaj("PoStrzalce")
            continue
        }
        OstatnioPominieta := ""

        if !WinActive("ahk_id " Dlg)
        {
            OstatniBlad := "Okno karty przestalo byc aktywne - przerwano, zeby nie wpisac rabatu w zle miejsce."
            Log("BLAD: " OstatniBlad)
            return -1
        }
        Send, {End}+{Home}
        Send, {Raw}%curRabat%
        Czekaj("PoWpisaniu")

        Send, {F10}                     ; zapis karty
        if !CzekajNaZamkniecie(Dlg)
        {
            OstatniBlad := "Po F10 (zapis) okno karty sie nie zamknelo (firma " curID ", karta " Zmienione + 1 ").`nMoze wyskoczylo okienko z bledem lub potwierdzeniem."
            Log("BLAD: " OstatniBlad)
            return -1
        }
        Zmienione++
        LiczbaZmienionych++
        Zapisane[Karta] := 1
        Log("Zapisano karte nr " Zmienione)

        Aktywuj(ListaHwnd)
        Send, {Down}                    ; nastepna karta
        Czekaj("PoStrzalce")
    }

    Aktywuj(ListaHwnd)
    Send, {Esc}                         ; zamkniecie listy kart
    if !CzekajNaZamkniecie(ListaHwnd)
    {
        OstatniBlad := "Nie zamknela sie lista kart po Esc (firma " curID ")."
        Log("BLAD: " OstatniBlad)
        return -1
    }
    Czekaj("PoEsc")
    Log("Firma " curID ": zmieniono " Zmienione " kart.")
    return Zmienione
}

; Zapisuje opis aktywnego okna i jego pol (do kalibracji i diagnostyki).
OpisOkna(Hwnd)
{
    WinGetTitle, tytul, ahk_id %Hwnd%
    WinGetClass, klasa, ahk_id %Hwnd%
    WinGet, lista, ControlList, ahk_id %Hwnd%
    ControlGetFocus, fokus, ahk_id %Hwnd%
    t := "Tytul: " tytul "`r`nKlasa: " klasa "`r`nAktywne pole: " fokus "`r`n`r`nPola:`r`n"
    Loop, Parse, lista, `n
    {
        ControlGetText, tx, %A_LoopField%, ahk_id %Hwnd%
        ControlGetPos, x, y, w, h, %A_LoopField%, ahk_id %Hwnd%
        t .= A_LoopField "  [" x "," y " " w "x" h "]  " SubStr(StrReplace(StrReplace(tx, "`r"), "`n", " "), 1, 60) "`r`n"
    }
    return t
}
