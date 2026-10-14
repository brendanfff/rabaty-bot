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

; --- Test 3: wpisywanie do okna (symulacja programu kasowego w osobnym procesie) ---
Run, "%A_AhkPath%" "%A_ScriptDir%\fake_kasa.ahk"
WinWait, Kasa TEST,, 10
Hwnd := WinExist("Kasa TEST")
Sprawdz(Hwnd, "okno kasy testowej otwarte")
Sleep, 500
WprowadzFirme(Hwnd, Firmy[1].id, Firmy[1].rabat)
WprowadzFirme(Hwnd, Firmy[4].id, Firmy[4].rabat)
Sleep, 1000
FileRead, Log, %A_ScriptDir%\kasa_log.txt
WinClose, ahk_id %Hwnd%
Oczekiwany := "1001{Enter}{F1}10{Enter}{Enter}A+1#{Enter}{F1}5{Enter}{Enter}"
Sprawdz(Log == Oczekiwany, "sekwencja klawiszy w oknie kasy: ID, Enter, F1, rabat, Enter, Enter")
Wynik .= "--- odebrane klawisze ---`n" Log "`n---`n"

FileDelete, %A_ScriptDir%\wynik.txt
FileAppend, %Wynik%, %A_ScriptDir%\wynik.txt
ExitApp, % (Bledy ? 1 : 0)

#Include %A_ScriptDir%\..\Rabaty_lib.ahk
