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
Sprawdz(Firmy.Length() == 5, "5 firm (jest: " Firmy.Length() ")")
Sprawdz(Firmy[1].id == "1001" && Firmy[1].rabat == "10", "firma 1 = 1001 / 10")
Sprawdz(Firmy[3].id == "1003" && Firmy[3].rabat == "30", "spacje obciete: 1003 / 30")
Sprawdz(Firmy[4].id == "A+1#", "ID ze znakami specjalnymi")
Sprawdz(Firmy[5].id == "5880", "ID w cudzyslowie (jak w starym programie)")
Sprawdz(PoliczDziesiatki(Firmy) == 1, "liczba rabatow 10 gr = 1")

; --- Test 2: bledne pliki ---
Sprawdz(!WczytajRabaty(A_ScriptDir "\nie_ma.txt", c, f, b), "brak pliku -> blad")
Sprawdz(!WczytajRabaty(A_ScriptDir "\rabaty_pusty.txt", c, f, b), "pusty plik -> blad")

; --- Test 3: pelna symulacja kasy (osobny proces) ---
FileDelete, %A_ScriptDir%\kasa_stan.txt
LogPlik := A_ScriptDir "\rabaty_log.txt"
FileDelete, %LogPlik%
Run, "%A_AhkPath%" "%A_ScriptDir%\fake_kasa.ahk"
WinWait, Kasa TEST - Firmy,, 10
FirmaHwnd := WinExist("Kasa TEST - Firmy")
Sprawdz(FirmaHwnd, "okno firm otwarte")
WinActivate, ahk_id %FirmaHwnd%
Sleep, 500
InitUst()
Sprawdz(Ust.IloscTab == 5, "domyslne ustawienia wczytane")
Ust.PoEnter := 200, Ust.PoOknie := 150, Ust.PoTab := 60, Ust.PoWpisaniu := 100, Ust.PoStrzalce := 200, Ust.PoEsc := 200, Ust.MaxCzekanie := 3000

; firma z 3 kartami (Taby)
w1 := WprowadzFirme(FirmaHwnd, "1001", "30")
Sprawdz(w1 == 3, "1001: zmieniono 3 karty (jest: " w1 ") " OstatniBlad)
; firma, ktorej 1. karta juz ma docelowy rabat (nie moze sie zatrzymac za wczesnie)
w3 := WprowadzFirme(FirmaHwnd, "1003", "20")
Sprawdz(w3 == 2, "1003: zmieniono 2 karty (jest: " w3 ") " OstatniBlad)
; po kalibracji: bezposrednio do pola rabatu
Ust.PoleRabatu := "Edit6", Ust.OknoKarty := "Modyfikacja karty"
w2 := WprowadzFirme(FirmaHwnd, "1002", "20")
Sprawdz(w2 == 1, "1002 (kalibracja): zmieniono 1 karte (jest: " w2 ") " OstatniBlad)
; lista wraca na gore po kazdym zapisie (jak prawdopodobnie w PetrolStationCL)
Ust.PoleRabatu := "", Ust.OknoKarty := ""
w5 := WprowadzFirme(FirmaHwnd, "1004", "25")
Sprawdz(w5 == 4, "1004 (lista wraca na gore): zmieniono 4 karty (jest: " w5 ") " OstatniBlad)
; po zapisie kursor ucieka z tabeli (strzalka nie dziala)
w6 := WprowadzFirme(FirmaHwnd, "1005", "41")
Sprawdz(w6 == 3, "1005 (kursor ucieka z tabeli): zmieniono 3 karty (jest: " w6 ") " OstatniBlad)
; jak w PetrolStationCL: lista wraca na gore po kazdym zamknieciu karty (zapis i Esc), karty 10 i 0 pomijane
w7 := WprowadzFirme(FirmaHwnd, "1006", "41")
Sprawdz(w7 == 2, "1006 (powrot na gore + pomijanie 10/0): zmieniono 2 karty (jest: " w7 ") " OstatniBlad)
; nieistniejaca firma - musi sie bezpiecznie zatrzymac
w4 := WprowadzFirme(FirmaHwnd, "9999", "15")
Sprawdz(w4 == -1 && InStr(OstatniBlad, "listy kart"), "nieznana firma -> bezpieczne zatrzymanie")

Sleep, 600
FileRead, Stan, %A_ScriptDir%\kasa_stan.txt
WinClose, ahk_id %FirmaHwnd%
Sprawdz(InStr(Stan, "1001=30,30,30|1002=20|1003=20,20|1004=25,25,25,25|1005=41,41,41|1006=41,10,0,41"), "rabaty na wszystkich kartach zmienione")
Sprawdz(InStr(Stan, "Zapisy=15"), "dokladnie 15 zapisow kart (bez zbednych)")
Sprawdz(InStr(Stan, "Lista=0") && InStr(Stan, "Karta=0"), "wszystkie okna kart zamkniete")
Wynik .= "--- stan kasy ---`n" Stan "`n---`n"

FileRead, L, %LogPlik%
Wynik .= "--- dziennik ---`n" L
FileDelete, %A_ScriptDir%\wynik.txt
FileAppend, %Wynik%, %A_ScriptDir%\wynik.txt
ExitApp, % (Bledy ? 1 : 0)

; Jesli program zlapalby wlasny Esc, test konczy sie bledem 3
$Esc::ExitApp, 3

#Include %A_ScriptDir%\..\Rabaty_lib.ahk
