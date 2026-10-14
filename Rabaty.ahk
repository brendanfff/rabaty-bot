#NoEnv
#SingleInstance Force
SetTitleMatchMode, 2
CoordMode, Mouse, Screen
SetWorkingDir, %A_ScriptDir%

MsgBox, 64, Program Rabaty - Gotowy, Program czuwa w tle!`n`n1. Otworz program kasowy i ustaw kursor w polu szukania.`n2. Nacisnij [Ctrl + S] i wybierz plik .txt z rabatami.`n`n[ESC] lub [Ctrl + Q] = Natychmiastowe zatrzymanie programu.
return

Esc::
^q::
SoundBeep, 750, 300
MsgBox, 16, AWARYJNE ZATRZYMANIE, Program zostal natychmiast przerwany!
ExitApp
return

^s::
GlowneWprowadzanie()
return

#Include %A_ScriptDir%\Rabaty_lib.ahk

GlowneWprowadzanie()
{
    static OstatniFolder := ""

    ; Zapamietaj okno programu kasowego (to, ktore bylo aktywne przy Ctrl+S)
    WinGet, KasaHwnd, ID, A

    if (OstatniFolder == "")
        OstatniFolder := A_ScriptDir

    ; Okno wyboru pliku z rabatami
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

    MsgBox, 262180, Wczytano plik, Plik: %NazwaPliku%`nCena na slupie: %CenaSlupa%`nLiczba firm: %TotalValid%`n`nRozpoczac wprowadzanie?
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

    for index, item in FirmList
    {
        curID := item.id
        curRabat := item.rabat

        MsgBox, 262147, Potwierdzenie zmiany ceny (%index%/%TotalValid%), Firma: %curID%`nCena na zmianie: %curRabat%`nCzy chcesz zmienic cene dla tej firmy?`n`n[Tak] = wprowadz  [Nie] = pomin  [Anuluj] = zakoncz
        IfMsgBox, Cancel
        {
            MsgBox, 48, Przerwano, Zakonczono wprowadzanie na zadanie uzytkownika.
            return
        }
        IfMsgBox, No
            continue

        WprowadzFirme(KasaHwnd, curID, curRabat)
    }

    SoundBeep, 1200, 300
    MsgBox, 64, Sukces, Pomyslnie przetworzono cala liste firm!
}
