#NoEnv
#SingleInstance Force
SetTitleMatchMode, 2
CoordMode, Mouse, Screen
SetWorkingDir, %A_ScriptDir%

WczytajUstawienia(A_ScriptDir "\Rabaty.ini")
LogPlik := A_ScriptDir "\rabaty_log.txt"

MsgBox, 64, Program Rabaty - Gotowy, Program czuwa w tle!`n`n1. Otworz program kasowy, okno z lista firm.`n2. Nacisnij [Ctrl + S] i wybierz plik .txt z rabatami.`n`n[Ctrl + K] = kalibracja pola rabatu (w oknie modyfikacji karty).`n[ESC] lub [Ctrl + Q] = Natychmiastowe zatrzymanie programu.
return

; $ - program nie reaguje na wlasne wysylane klawisze (sam wysyla Esc do kasy)
$Esc::
$^q::
SoundBeep, 750, 300
MsgBox, 16, AWARYJNE ZATRZYMANIE, Program zostal natychmiast przerwany!
ExitApp
return

^s::
GlowneWprowadzanie()
return

; Kalibracja: otworz okno modyfikacji karty (F4), kliknij w pole rabatu i nacisnij Ctrl+K
^k::
Kalibracja()
return

#Include %A_ScriptDir%\Rabaty_lib.ahk

Kalibracja()
{
    WinGet, h, ID, A
    WinGetClass, klasa, ahk_id %h%
    ControlGetFocus, pole, ahk_id %h%
    opis := OpisOkna(h)
    FileDelete, %A_ScriptDir%\diagnostyka.txt
    FileAppend, %opis%, %A_ScriptDir%\diagnostyka.txt
    if (pole == "")
    {
        MsgBox, 48, Kalibracja, Nie udalo sie odczytac aktywnego pola.`nProgram dalej bedzie uzywal Tabow (IloscTab w Rabaty.ini).`n`nOpis okna zapisano w diagnostyka.txt.
        return
    }
    ControlGetText, wart, %pole%, ahk_id %h%
    MsgBox, 262180, Kalibracja, Okno: ahk_class %klasa%`nPole rabatu: %pole%`nObecna wartosc pola: %wart%`n`nZapisac to jako okno modyfikacji karty i pole rabatu?
    IfMsgBox, No
        return
    Ust.OknoKarty := "ahk_class " klasa
    Ust.PoleRabatu := pole
    ZapiszUstawienia(A_ScriptDir "\Rabaty.ini")
    MsgBox, 64, Kalibracja, Zapisano w Rabaty.ini. Od teraz program sam ustawi kursor w polu rabatu.
}

GlowneWprowadzanie()
{
    static OstatniFolder := ""
    WinGet, KasaHwnd, ID, A
    if (OstatniFolder == "")
        OstatniFolder := A_ScriptDir

    FileSelectFile, Sciezka, 3, %OstatniFolder%, Wybierz plik z rabatami (.txt), Pliki tekstowe (*.txt)
    if (ErrorLevel || Sciezka == "")
    {
        TrayTip, Rabaty, Nie wybrano pliku - anulowano., 3
        return
    }
    SplitPath, Sciezka, NazwaPliku, OstatniFolder

    if !WczytajRabaty(Sciezka, CenaSlupa, FirmList, Blad)
    {
        MsgBox, 16, Blad, %Blad%
        return
    }
    TotalValid := FirmList.Length()
    CountTens := PoliczDziesiatki(FirmList)

    MsgBox, 262180, Wczytano plik, Plik: %NazwaPliku%`nCena na slupie: %CenaSlupa%`nLiczba firm: %TotalValid%`n`nUpewnij sie, ze w kasie jest otwarte okno z lista firm.`nRozpoczac wprowadzanie?
    IfMsgBox, No
        return

    Ratio := (CountTens / TotalValid) * 100
    if (CountTens > 0 && Ratio >= 70)
    {
        MsgBox, 262180, OSTRZEZENIE: Wykryto karty PB (10 gr)!, Wykryto %CountTens% z %TotalValid% firm z rabatem 10 gr.`nPrawdopodobnie jest to lista BENZYNY (PB), a nie Diesla!`n`nCzy chcesz nadpisac WSZYSTKIE karty na liscie?`n`n[Tak] = Zmien mimo to`n[Nie] = Anuluj i zachowaj stare rabaty
        IfMsgBox, No
            return
    }

    SoundBeep, 1000, 150
    Sleep, 300
    LiczbaZmienionych := 0
    FileDelete, %LogPlik%
    Log("Plik: " Sciezka ", firm: " TotalValid)

    for index, item in FirmList
    {
        curID := item.id
        curRabat := item.rabat
        MsgBox, 262147, Potwierdzenie zmiany ceny (%index%/%TotalValid%), Firma: %curID%`nRabat (gr): %curRabat%`nCzy chcesz zmienic rabat na WSZYSTKICH kartach tej firmy?`n`n[Tak] = wprowadz  [Nie] = pomin  [Anuluj] = zakoncz
        IfMsgBox, Cancel
        {
            MsgBox, 48, Przerwano, Zakonczono wprowadzanie na zadanie uzytkownika.
            return
        }
        IfMsgBox, No
            continue

        wynik := WprowadzFirme(KasaHwnd, curID, curRabat)
        if (wynik < 0)
        {
            SoundBeep, 500, 400
            MsgBox, 16, Zatrzymano, %OstatniBlad%`n`nProgram zatrzymal sie, zeby nic nie wpisac w zle miejsce. Sprawdz okna w kasie.`nSzczegoly: rabaty_log.txt
            return
        }
        TrayTip, Rabaty, Firma %curID%: zmieniono kart: %wynik%, 2
    }
    SoundBeep, 1200, 300
    MsgBox, 64, Sukces, Pomyslnie przetworzono cala liste firm!`nZmienionych kart: %LiczbaZmienionych%
}
