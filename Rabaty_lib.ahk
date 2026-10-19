; ===== Logika programu Rabaty (wspolna dla programu i testow) =====
global Ust := ""
global OstatniBlad := ""
global LiczbaZmienionych := 0
global LogPlik := ""
global OstPominiete10 := 0, OstPominiete0 := 0, ListaKlasa := ""
global OstPB := 0, OstZmienione10 := 0, OstUwagi := "", PytajO10Fn := ""

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
    Ust.BezPotwierdzen := 0   ; 1 = nie pytaj o kazda firme (przelacznik w oknie startowym)
    Ust.SlowaPB := "PB,PB95,PB98,BENZYNA,BENZ"   ; oznaczenia karty benzyny w nazwisku/imieniu/nr rej.
    Ust.Karty10BezPB := "pytaj"  ; karty z 10 gr BEZ oznaczenia PB: pytaj / zmieniaj / pomijaj
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
        if (StrLen(fID) >= 2 && SubStr(fID, 1, 1) == """" && SubStr(fID, 0) == """")
            fID := SubStr(fID, 2, StrLen(fID) - 2)
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

; Aktywuje liste kart i ustawia kursor z powrotem w tabeli kart.
UstawTabele(ListaHwnd, Siatka)
{
    Aktywuj(ListaHwnd)
    if (Siatka != "")
    {
        ControlGetFocus, f, ahk_id %ListaHwnd%
        if (f != Siatka)
        {
            ControlFocus, %Siatka%, ahk_id %ListaHwnd%
            Sleep, 100
        }
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

; Czy karta jest oznaczona jako benzyna: ktores pole tekstowe (nazwisko, imie, nr rej.) to "PB"
; albo zawiera slowo PB i nie ma cyfr (zeby nie lapac tablic z Bialegostoku typu "PB 12345").
; Zwraca tekst pola z oznaczeniem albo "".
CzyKartaPB(Dlg, Pole)
{
    InitUst()
    slowa := "," Ust.SlowaPB ","
    WinGet, lista, ControlList, ahk_id %Dlg%
    Loop, Parse, lista, `n
    {
        if (A_LoopField == Pole)
            continue
        ControlGetText, tx, %A_LoopField%, ahk_id %Dlg%
        if (tx == "")
            continue
        StringUpper, tu, tx
        zwarty := RegExReplace(tu, "[\s\.\-_,;:/]")
        if (zwarty != "" && InStr(slowa, "," zwarty ","))
            return tx
        if !RegExMatch(tu, "\d")
        {
            Loop, Parse, tu, % " .-_,;:/"
                if (A_LoopField != "" && InStr(slowa, "," A_LoopField ","))
                    return tx
        }
    }
    return ""
}

DecyzjaO10(curID, curRabat, Dlg)
{
    tryb := Ust.Karty10BezPB
    if (tryb = "zmieniaj")
        return "tak"
    if (tryb = "pomijaj")
        return "nie"
    if IsObject(PytajO10Fn)
        return PytajO10Fn.Call(curID, curRabat)
    return "nie"
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

; Wprowadza rabat dla wszystkich kart jednej firmy (logika jak w starym programie "nowa zmiana cen.exe"):
; ID, Enter, F10 (lista kart). Dla karty nr k: poczatek listy + k razy strzalka w dol, F4, pole rabatu,
; rabat, F10 (zapis). Po zamknieciu karty lista w PetrolStationCL wraca na gore - dlatego pozycja liczona od gory.
; Karty z rabatem 10 lub 0 (benzyna / wylaczone) sa pomijane bez zmian.
; Koniec listy = otworzyla sie ta sama karta co poprzednio (strzalki nie maja juz gdzie zejsc).
; Zwraca liczbe zmienionych kart albo -1 przy bledzie (opis w OstatniBlad).
WprowadzFirme(FirmaHwnd, curID, curRabat, Probny := false)
{
    InitUst()
    OstatniBlad := ""
    OstPominiete10 := 0, OstPominiete0 := 0, OstPB := 0, OstZmienione10 := 0, OstUwagi := ""
    Decyzja10 := ""
    Log("=== Firma " curID ", rabat " curRabat (Probny ? " (TRYB PROBNY - bez zapisu)" : ""))
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
        return -2
    }
    WinGetClass, kl, ahk_id %ListaHwnd%
    if (ListaKlasa != "" && kl != ListaKlasa)
    {
        OstatniBlad := "Po F10 otworzylo sie inne okno niz lista kart (firma " curID ").`nMoze kasa pokazala komunikat, np. ze nie ma takiej firmy."
        Log("BLAD: " OstatniBlad " (klasa " kl ")")
        return -1
    }
    ListaKlasa := kl
    WinGetTitle, t, ahk_id %ListaHwnd%
    ControlGetFocus, Siatka, ahk_id %ListaHwnd%
    Log("Lista kart: " t " (tabela: " Siatka ")")

    Zmienione := 0
    Pominiete := 0
    Poprzednia := ""
    k := 0
    Loop
    {
        if (k >= Ust.MaxKart)
        {
            OstatniBlad := "Przekroczono limit " Ust.MaxKart " kart dla firmy " curID "."
            Log("BLAD: " OstatniBlad)
            return -1
        }
        ; ustaw sie na karcie nr k (liczac od gory)
        UstawTabele(ListaHwnd, Siatka)
        Send, ^{Home}
        Sleep, 50
        Loop, %k%
        {
            Send, {Down}
            Sleep, 30
        }
        Czekaj("PoStrzalce")

        Send, {F4}                      ; modyfikacja karty
        Dlg := CzekajNaNoweOkno(ListaHwnd, Ust.OknoKarty)
        if !Dlg
        {
            OstatniBlad := "Po F4 nie otworzylo sie okno modyfikacji karty (firma " curID ", karta " k + 1 ")."
            Log("BLAD: " OstatniBlad)
            return -1
        }

        Wartosc := PrzejdzDoPolaRabatu(Dlg, Pole)
        Karta := IdentyfikatorKarty(Dlg, Pole)
        Log("Karta " k + 1 ": [" Karta "] pole " Pole " = " Wartosc)

        if (Karta == "")
        {
            Send, {Esc}
            OstatniBlad := "Nie mozna odczytac danych karty (firma " curID ") - nie wiadomo, kiedy koniec listy."
            Log("BLAD: " OstatniBlad)
            return -1
        }

        if (Karta == Poprzednia)
        {
            ; ta sama karta co poprzednio = koniec listy
            Send, {Esc}
            if !CzekajNaZamkniecie(Dlg)
            {
                OstatniBlad := "Nie zamknelo sie okno karty po Esc (firma " curID ")."
                Log("BLAD: " OstatniBlad)
                return -1
            }
            Log("Koniec listy kart.")
            break
        }
        Poprzednia := Karta

        Pominac := ""
        PB := CzyKartaPB(Dlg, Pole)
        if (PB != "")
        {
            ; karta oznaczona jako benzyna (PB w nazwisku / imieniu / nr rej.) - stala znizka, nie ruszamy
            Pominac := "karta PB (pole: " PB ")"
            OstPB++
            if !TakiSamRabat(Wartosc, "10")
                OstUwagi .= "karta PB z rabatem " Wartosc " gr (zwykle 10) - sprawdz; "
        }
        else if TakiSamRabat(Wartosc, "0")
        {
            Pominac := "rabat 0"
            OstPominiete0++
        }
        else if TakiSamRabat(Wartosc, "10")
        {
            if TakiSamRabat(curRabat, "10")
            {
                Pominac := "ma juz 10 gr"
                OstPominiete10++
            }
            else
            {
                ; 10 gr bez oznaczenia PB: moze to diesel z rabatem 10 gr, a moze nieoznaczona karta PB
                if (Decyzja10 == "")
                    Decyzja10 := DecyzjaO10(curID, curRabat, Dlg)
                if (Decyzja10 == "stop")
                {
                    Send, {Esc}
                    OstatniBlad := "Zatrzymano na pytaniu o karty 10 gr (firma " curID ")."
                    Log("BLAD: " OstatniBlad)
                    return -1
                }
                if (Decyzja10 == "tak")
                {
                    OstZmienione10++
                    Log("10 gr bez oznaczenia PB - zmieniam (decyzja dla firmy).")
                    Aktywuj(Dlg)
                    ControlGetFocus, f, ahk_id %Dlg%
                    if (Pole != "" && f != Pole)
                        ControlFocus, %Pole%, ahk_id %Dlg%
                }
                else
                {
                    Pominac := "10 gr bez oznaczenia PB (decyzja: pomin)"
                    OstPominiete10++
                }
            }
        }

        if (Pominac != "")
        {
            Log("Karta pominieta bez zmian: " Pominac ", rabat " Wartosc ".")
            Send, {Esc}
            if !CzekajNaZamkniecie(Dlg)
            {
                OstatniBlad := "Nie zamknelo sie okno karty po Esc (firma " curID ")."
                Log("BLAD: " OstatniBlad)
                return -1
            }
            Pominiete++
        }
        else if (Probny)
        {
            Log("TRYB PROBNY: zmienilbym rabat " Wartosc " -> " curRabat " (zamykam bez zapisu).")
            Send, {Esc}
            if !CzekajNaZamkniecie(Dlg)
            {
                OstatniBlad := "Nie zamknelo sie okno karty po Esc (firma " curID ")."
                Log("BLAD: " OstatniBlad)
                return -1
            }
            Zmienione++
        }
        else
        {
            if !WinActive("ahk_id " Dlg)
            {
                OstatniBlad := "Okno karty przestalo byc aktywne - przerwano, zeby nie wpisac rabatu w zle miejsce."
                Log("BLAD: " OstatniBlad)
                return -1
            }
            Send, {End}+{Home}
            Send, {Raw}%curRabat%
            Czekaj("PoWpisaniu")
            Send, {F10}                 ; zapis karty
            if !CzekajNaZamkniecie(Dlg)
            {
                OstatniBlad := "Po F10 (zapis) okno karty sie nie zamknelo (firma " curID ", karta " k + 1 ").`nMoze wyskoczylo okienko z bledem lub potwierdzeniem."
                Log("BLAD: " OstatniBlad)
                return -1
            }
            Zmienione++
            LiczbaZmienionych++
            Log("Zapisano karte " k + 1)
        }
        k++
    }

    UstawTabele(ListaHwnd, Siatka)
    Send, {Esc}                         ; zamkniecie listy kart
    if !CzekajNaZamkniecie(ListaHwnd)
    {
        OstatniBlad := "Nie zamknela sie lista kart po Esc (firma " curID ")."
        Log("BLAD: " OstatniBlad)
        return -1
    }
    Czekaj("PoEsc")
    Log("Firma " curID ": zmieniono " Zmienione " kart (w tym 10 gr bez PB: " OstZmienione10 "), pominieto: PB " OstPB ", 10 gr " OstPominiete10 ", 0 " OstPominiete0 ".")
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
