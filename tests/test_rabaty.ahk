; Testy automatyczne programu Rabaty (uruchamiane na GitHub Actions)
#NoEnv
#SingleInstance Force
SetWorkingDir, %A_ScriptDir%
global Wynik := ""
global Bledy := 0

Sprawdz(warunek, opis)
{
    Wynik .= (warunek ? "OK   " : "FAIL ") opis "`n"
    if !warunek
        Bledy++
}

; --- Test 1: wczytywanie poprawnego pliku ---
ok := WczytajRabaty(A_ScriptDir "\rabaty_test.txt", Cena, Firmy, Blad)
Sprawdz(ok, "wczytanie pliku testowego")
Sprawdz(Cena == "6.49", "cena slupa = 6.49 (jest: " Cena ")")
Sprawdz(Firmy.Length() == 4, "4 firmy (jest: " Firmy.Length() ")")
Sprawdz(Firmy[1].id == "1001" && Firmy[1].rabat == "10", "firma 1 = 1001 / 10")
Sprawdz(Firmy[3].id == "1003" && Firmy[3].rabat == "30", "spacje obciete: 1003 / 30")
Sprawdz(Firmy[4].id == "A+1#", "ID ze znakami specjalnymi")
Sprawdz(PoliczDziesiatki(Firmy) == 1, "liczba rabatow 10 gr = 1")

; --- Test 2: bledne pliki ---
Sprawdz(!WczytajRabaty(A_ScriptDir "\nie_ma.txt", c, f, b), "brak pliku -> blad")
Sprawdz(!WczytajRabaty(A_ScriptDir "\rabaty_pusty.txt", c, f, b), "pusty plik -> blad")

; --- Test 3: wpisywanie do okna (symulacja programu kasowego) ---
Gui, Kasa:New, +AlwaysOnTop, Kasa TEST
Gui, Kasa:Add, Edit, vPole w400 h300 Multi WantReturn hwndPoleHwnd
Gui, Kasa:Show, w420 h320
global Log := ""
OnMessage(0x100, "KlawiszWcisniety")
OnMessage(0x102, "ZnakWpisany")
WinWaitActive, Kasa TEST,, 5
Hwnd := WinExist("Kasa TEST")
ControlFocus, Edit1, ahk_id %Hwnd%

WprowadzFirme(Hwnd, Firmy[1].id, Firmy[1].rabat)
WprowadzFirme(Hwnd, Firmy[4].id, Firmy[4].rabat)
Sleep, 500
Oczekiwany := "1001{Enter}{F1}10{Enter}{Enter}A+1#{Enter}{F1}5{Enter}{Enter}"
Sprawdz(Log == Oczekiwany, "sekwencja klawiszy w oknie kasy: ID, Enter, F1, rabat, Enter, Enter")
Wynik .= "--- odebrane klawisze ---`n" Log "`n---`n"

FileDelete, %A_ScriptDir%\wynik.txt
FileAppend, %Wynik%, %A_ScriptDir%\wynik.txt
ExitApp, % (Bledy ? 1 : 0)

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

#Include %A_ScriptDir%\..\Rabaty_lib.ahk
