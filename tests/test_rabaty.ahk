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
Sprawdz(w7 == 3 && OstZmienione10 == 1 && OstPominiete0 == 1, "1006 (powrot na gore, 10 bez PB zmieniane, 0 pomijane): zmieniono 3 karty (jest: " w7 ") " OstatniBlad)
; nieistniejaca firma - musi sie bezpiecznie zatrzymac
w4 := WprowadzFirme(FirmaHwnd, "9999", "15")
Sprawdz(w4 == -2 && InStr(OstatniBlad, "listy kart"), "nieznana firma -> wykryta (do pominiecia)")
; karty PB: oznaczenie w nr rej. / nazwisku, tablica "PB 12345" to NIE benzyna, 10 gr bez PB -> decyzja "tak"
global OdpO10 := {"k1007": "tak"}
PytajO10Fn := Func("FakePytajO10")
w9 := WprowadzFirme(FirmaHwnd, "1007", "45")
Sprawdz(w9 == 2 && OstPB == 2 && OstZmienione10 == 1, "1007 karty PB: zmieniono 2 (10 gr bez PB + tablica PB 12345), pominieto 2 PB (jest: " w9 ", PB " OstPB ", z10 " OstZmienione10 ")")
; tryb "pomijaj": karty 10 gr bez PB zostaja
Ust.Karty10BezPBTryb := "pomijaj"
w10 := WprowadzFirme(FirmaHwnd, "1008", "45")
Sprawdz(w10 == 1 && OstPominiete10 == 1, "1008 tryb pomijaj: zmieniono 1, 10 gr zostawione (jest: " w10 ")")
Ust.Karty10BezPBTryb := "zmieniaj"
; karta PB z innym rabatem niz 10 (takze 0) -> przywrocenie 10 gr
w11 := WprowadzFirme(FirmaHwnd, "1009", "45")
Sprawdz(w11 == 3 && OstPBNaprawione == 2, "1009 karty PB z 45 i 0 -> 10 gr, zwykla -> 45 (jest: " w11 ", naprawione PB " OstPBNaprawione ")")
; tryb probny: nic nie zapisuje
w8 := WprowadzFirme(FirmaHwnd, "1006", "55", true)
Sprawdz(w8 == 3 && OstPominiete0 == 1, "tryb probny: zmienilby 3, pominal 0 (jest: " w8 ")")

Sleep, 600
FileRead, Stan, %A_ScriptDir%\kasa_stan.txt
WinClose, ahk_id %FirmaHwnd%
Sprawdz(InStr(Stan, "1001=30,30,30|1002=20|1003=20,20|1004=25,25,25,25|1005=41,41,41|1006=41,41,0,41|1007=10,45,45,10|1008=10,45|1009=10,10,45"), "rabaty na wszystkich kartach zmienione")
Sprawdz(InStr(Stan, "Zapisy=22"), "dokladnie 22 zapisow kart (bez zbednych)")
Sprawdz(InStr(Stan, "Lista=0") && InStr(Stan, "Karta=0"), "wszystkie okna kart zamkniete")
Wynik .= "--- stan kasy ---`n" Stan "`n---`n"

FileRead, L, %LogPlik%
Wynik .= "--- dziennik ---`n" L
FileDelete, %A_ScriptDir%\wynik.txt
FileAppend, %Wynik%, %A_ScriptDir%\wynik.txt
ExitApp, % (Bledy ? 1 : 0)

FakePytajO10(id, rabat)
{
    return OdpO10.HasKey("k" id) ? OdpO10["k" id] : "nie"
}

; Jesli program zlapalby wlasny Esc, test konczy sie bledem 3
$Esc::ExitApp, 3

#Include %A_ScriptDir%\..\Rabaty_lib.ahk
