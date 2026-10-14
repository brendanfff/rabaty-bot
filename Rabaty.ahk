#NoEnv
#SingleInstance Force
SetTitleMatchMode, 2
CoordMode, Mouse, Screen
SetWorkingDir, %A_ScriptDir%

MsgBox, 64, Program Rabaty - Gotowy, Program czuwa w tle!`n`n1. Otworz program kasowy i ustaw kursor w polu szukania.`n2. Nacisnij [Ctrl + S], aby rozpoczac.`n`n[ESC] lub [Ctrl + Q] = Natychmiastowy ABORT.
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


GlowneWprowadzanie()
{
    IfNotExist, rabaty.txt
    {
        MsgBox, 16, Blad, Nie znaleziono pliku rabaty.txt w folderze programu!
        return
    }

    FileRead, FileContent, rabaty.txt
    Lines := StrSplit(FileContent, "`n", "`r")

    if (Lines.Length() < 2)
    {
        MsgBox, 16, Blad, Plik rabaty.txt jest pusty lub niepoprawny!
        return
    }

    CenaSlupa := Trim(Lines[1])
    FirmList := []
    TotalValid := 0
    CountTens := 0

    Loop, % Lines.Length()
    {
        if (A_Index == 1)
            continue

        CurrentLine := Trim(Lines[A_Index])
        if (CurrentLine == "")
            continue

        Fields := StrSplit(CurrentLine, ";")
        if (Fields.Length() < 3)
            continue

        TotalValid++
        fID := Trim(Fields[1])
        fCena := Trim(Fields[2])
        fRabat := Trim(Fields[3])

        if (fRabat = "10")
            CountTens++

        FirmList.Push({"id": fID, "cena": fCena, "rabat": fRabat})
    }

    if (TotalValid == 0)
    {
        MsgBox, 16, Blad, Brak poprawnych wierszy z firmami!
        return
    }

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

        MsgBox, 262147, Potwierdzenie zmiany ceny, Firma: %curID%`nCena na zmianie: %curRabat%`nCzy chcesz zmienic cene dla tej firmy?
        
        IfMsgBox, Cancel
        {
            MsgBox, 48, Przerwano, Zakonczono wprowadzanie na zadanie uzytkownika.
            return
        }
        IfMsgBox, No
        {
            continue
        }

        Send, %curID%
        Sleep, 200
        Send, {Enter}
        Sleep, 400

        Send, {F1}
        Sleep, 300

        Send, %curRabat%
        Sleep, 200
        Send, {Enter}
        Sleep, 300
        Send, {Enter}
        Sleep, 400
    }

    SoundBeep, 1200, 300
    MsgBox, 64, Sukces, Pomyslnie przetworzono cala liste firm!
}
