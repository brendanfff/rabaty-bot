#NoEnv
#SingleInstance Force
SetTitleMatchMode, 2
CoordMode, Mouse, Screen
SetWorkingDir, %A_ScriptDir%

global Przetwarzanie := false
global Raport := [], RaportInfo := {}
global PlikPostepu := A_ScriptDir "\Rabaty_postep.ini"
global OdpFirmy := ""
global OdpStart := "", ChkAuto := 0, ChkProbny := 0

WczytajUstawienia(A_ScriptDir "\Rabaty.ini")
LogPlik := A_ScriptDir "\rabaty_log.txt"
PytajO10Fn := Func("PytajO10")
OnExit("PrzyZamknieciu")
Menu, Tray, Tip, Rabaty - Ctrl+S start

MsgBox, 64, Program Rabaty - Gotowy, Program czuwa w tle!`n`n1. Otworz w kasie okno z lista firm.`n2. Nacisnij [Ctrl + S] i wybierz plik .txt z rabatami.`n`n[Ctrl + K] = kalibracja pola rabatu (w oknie modyfikacji karty).`n[ESC] lub [Ctrl + P] = zatrzymanie (dziala tylko w trakcie wprowadzania).`n[Ctrl + Q] = zamkniecie programu.`n`nKarty PB (oznaczenie w nazwisku / imieniu / nr rej.): zostaja na 10 gr,`nkarta PB z innym rabatem jest przywracana na 10 gr.`nKarty bez PB dostaja rabat z pliku (takze 0 gr). Rabat na minusie w pliku = 0 gr.
return

; Esc i Ctrl+P przechwytywane TYLKO w trakcie wprowadzania - poza tym dzialaja normalnie w kasie.
; $ = program nie reaguje na wlasne wysylane klawisze (sam wysyla Esc do kasy).
#If Przetwarzanie
$Esc::
$^p::
Zatrzymaj()
return
#If

$^q::
if (Przetwarzanie)
    Zatrzymaj()
ExitApp
return

^s::
if !Przetwarzanie
    GlowneWprowadzanie()
return

; Kalibracja: otworz okno modyfikacji karty (F4), kliknij w pole rabatu i nacisnij Ctrl+K
^k::
if !Przetwarzanie
    Kalibracja()
return

PytTak:
OdpFirmy := "tak"
Gui, Pyt:Destroy
return
PytNie:
OdpFirmy := "nie"
Gui, Pyt:Destroy
return
PytWszystkie:
OdpFirmy := "wszystkie"
Gui, Pyt:Destroy
return
PytKoniec:
PytGuiClose:
OdpFirmy := "koniec"
Gui, Pyt:Destroy
return

StartOK:
Gui, Start:Submit
OdpStart := "start"
Gui, Start:Destroy
return
StartAnuluj:
StartGuiClose:
StartGuiEscape:
OdpStart := "anuluj"
Gui, Start:Destroy
return

#Include %A_ScriptDir%\Rabaty_lib.ahk

Zatrzymaj()
{
    SoundBeep, 750, 300
    Log("ZATRZYMANO klawiszem przez uzytkownika.")
    ZapiszRaport("PRZERWANO (Esc / Ctrl+P / Ctrl+Q)")
    Przetwarzanie := false
    MsgBox, 16, AWARYJNE ZATRZYMANIE, Program zostal natychmiast przerwany!`n`nRaport zapisano. Przy nastepnym Ctrl+S mozna wznowic od miejsca przerwania.
    ExitApp
}

PrzyZamknieciu()
{
    if (Przetwarzanie)
        ZapiszRaport("PRZERWANO (zamkniecie programu)")
}

; Okno pytania o firme: Tak / Nie (pomin) / Tak dla wszystkich / Zakoncz
PytajFirme(index, total, id, rabat, probny)
{
    OdpFirmy := ""
    tryb := probny ? "  [TRYB PROBNY]" : ""
    Gui, Pyt:New, +AlwaysOnTop -MinimizeBox, Potwierdzenie zmiany (%index%/%total%)%tryb%
    Gui, Pyt:Font, s10
    Gui, Pyt:Add, Text, w420, Firma: %id%`nRabat (gr): %rabat%`n`nZmienic rabat na wszystkich kartach tej firmy?`n(karty PB zostana na 10 gr)
    Gui, Pyt:Add, Button, w95 Default gPytTak, &Tak
    Gui, Pyt:Add, Button, x+8 w95 gPytNie, &Nie (pomin)
    Gui, Pyt:Add, Button, x+8 w150 gPytWszystkie, Tak dla &wszystkich
    Gui, Pyt:Add, Button, xm w95 gPytKoniec, Zakoncz
    Gui, Pyt:Show
    while (OdpFirmy == "")
        Sleep, 50
    return OdpFirmy
}

DodajDoRaportu(id, rabat, zmienione, p10, p0, status, pb := 0, z10 := 0, uwagi := "")
{
    uwaga := uwagi
    if (zmienione == 0 && (p10 + p0 + pb) > 0 && !TakiSamRabat(rabat, "10"))
        uwaga .= "SPRAWDZ RECZNIE: nic nie zmieniono (wszystkie karty PB / 10 gr / 0); "
    if (z10 > 0)
        uwaga .= "zmieniono " z10 " kart z 10 gr bez oznaczenia PB; "
    Raport.Push({"id": id, "rabat": rabat, "z": zmienione, "p10": p10, "p0": p0, "pb": pb, "z10": z10, "status": status, "uwaga": uwaga})
}

PytajO10(curID, curRabat)
{
    SoundBeep, 900, 200
    MsgBox, 262147, Karty 10 gr bez oznaczenia PB, Firma %curID% ma karte z rabatem 10 gr, ale BEZ oznaczenia PB`n(w nazwisku, imieniu ani nr rejestracyjnym).`n`nTo moze byc diesel z rabatem 10 gr albo nieoznaczona karta benzyny.`n`n[Tak] = zmien takie karty tej firmy na %curRabat% gr`n[Nie] = zostaw je z 10 gr`n[Anuluj] = zatrzymaj program`n`n(Decyzja dotyczy wszystkich takich kart tej firmy.)
    IfMsgBox, Yes
        return "tak"
    IfMsgBox, No
        return "nie"
    return "stop"
}

ZapiszRaport(koniec)
{
    if (!IsObject(RaportInfo) || RaportInfo.plik == "")
        return
    FormatTime, teraz,, yyyy-MM-dd HH:mm
    t := "RAPORT RABATY - " teraz "`r`nPlik: " RaportInfo.plik "`r`nTryb: " (RaportInfo.probny ? "PROBNY (nic nie zapisano)" : "normalny") "`r`nWynik: " koniec "`r`n`r`n"
    sz := 0, sz10 := 0, sz0 := 0, uw := ""
    t .= "ID;RABAT;ZMIENIONE KARTY;W TYM 10 GR BEZ PB;POMINIETE PB;POMINIETE 10 GR;POMINIETE 0;STATUS;UWAGI`r`n"
    szpb := 0
    for i, r in Raport
    {
        t .= r.id ";" r.rabat ";" r.z ";" r.z10 ";" r.pb ";" r.p10 ";" r.p0 ";" r.status ";" r.uwaga "`r`n"
        sz += r.z, sz10 += r.p10, sz0 += r.p0, szpb += r.pb
        if (r.uwaga != "" || (r.status != "OK" && r.status != "pominieta przez uzytkownika"))
            uw .= "  " r.id " - " (r.uwaga != "" ? r.uwaga : r.status) "`r`n"
    }
    t .= "`r`nRAZEM: zmienione karty " (RaportInfo.probny ? "(zmienilby) " : "") sz ", pominiete karty PB: " szpb ", pominiete 10 gr: " sz10 ", pominiete 0: " sz0 "`r`n"
    t .= "`r`nDO SPRAWDZENIA RECZNIE:`r`n" (uw != "" ? uw : "  brak`r`n")
    FileDelete, % RaportInfo.raport
    FileAppend, %t%, % RaportInfo.raport
}

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

    ; wznowienie od miejsca przerwania
    Start := 1
    IniRead, pPlik, %PlikPostepu%, Postep, Plik, %A_Space%
    IniRead, pNast, %PlikPostepu%, Postep, Nastepna, 0
    if (pPlik = Sciezka && pNast > 1 && pNast <= TotalValid)
    {
        nid := FirmList[pNast].id
        MsgBox, 262147, Wznowienie, Ten plik byl juz czesciowo wprowadzony.`n`nWznowic od firmy nr %pNast% z %TotalValid% (ID %nid%)?`n`n[Tak] = wznow od tej firmy`n[Nie] = zacznij od poczatku`n[Anuluj] = nic nie rob
        IfMsgBox, Cancel
            return
        IfMsgBox, Yes
            Start := pNast + 0
    }

    info10 := CountTens > 0 ? "`nFirm z rabatem 10 gr w pliku: " CountTens " (to moze byc normalne - sprawdz raport na koniec)" : ""
    ; okno startowe z przelacznikami
    OdpStart := ""
    auto := Ust.BezPotwierdzen ? 1 : 0
    Gui, Start:New, +AlwaysOnTop -MinimizeBox, Wczytano plik
    Gui, Start:Font, s10
    Gui, Start:Add, Text, w440, Plik: %NazwaPliku%`nCena na slupie: %CenaSlupa%`nLiczba firm: %TotalValid%%info10%`nStart od firmy nr: %Start%`n`nUpewnij sie, ze w kasie jest otwarte okno z lista firm.
    Gui, Start:Add, CheckBox, vChkAuto Checked%auto% y+12, Wprowadzaj &bez potwierdzania kazdej firmy (automatycznie)
    Gui, Start:Add, CheckBox, vChkProbny, Tryb &probny (przejdzie po kartach, nic nie zapisze w kasie)
    Gui, Start:Add, Text, w440 cGray, Zatrzymanie w kazdej chwili: Esc lub Ctrl + P.
    Gui, Start:Add, Button, w110 Default gStartOK y+12, &Start
    Gui, Start:Add, Button, x+10 w110 gStartAnuluj, Anuluj
    Gui, Start:Show
    while (OdpStart == "")
        Sleep, 50
    if (OdpStart != "start")
        return
    Probny := ChkProbny ? true : false
    if ((ChkAuto ? 1 : 0) != Ust.BezPotwierdzen)
    {
        Ust.BezPotwierdzen := ChkAuto ? 1 : 0
        ZapiszUstawienia(A_ScriptDir "\Rabaty.ini")
    }

    FormatTime, znacznik,, yyyy-MM-dd_HHmm
    Raport := []
    RaportInfo := {"plik": Sciezka, "probny": Probny, "raport": A_ScriptDir "\raport_" znacznik (Probny ? "_probny" : "") ".txt"}
    LiczbaZmienionych := 0
    FileDelete, %LogPlik%
    Log("Plik: " Sciezka ", firm: " TotalValid ", start od: " Start (Probny ? ", TRYB PROBNY" : "") (ChkAuto ? ", BEZ POTWIERDZEN" : ""))

    Przetwarzanie := true
    SoundBeep, 1000, 150
    Sleep, 300
    Wszystkie := Ust.BezPotwierdzen ? true : false
    Koniec := "ZAKONCZONO - cala lista"

    for index, item in FirmList
    {
        if (index < Start)
            continue
        curID := item.id
        curRabat := item.rabat

        if (!Wszystkie)
        {
            odp := PytajFirme(index, TotalValid, curID, curRabat, Probny)
            if (odp == "koniec")
            {
                Koniec := "PRZERWANO przez uzytkownika na firmie nr " index
                if !Probny
                    IniWrite, %index%, %PlikPostepu%, Postep, Nastepna
                break
            }
            if (odp == "nie")
            {
                DodajDoRaportu(curID, curRabat, 0, 0, 0, "pominieta przez uzytkownika")
                continue
            }
            if (odp == "wszystkie")
                Wszystkie := true
        }

        if !Probny
        {
            IniWrite, %Sciezka%, %PlikPostepu%, Postep, Plik
            IniWrite, %index%, %PlikPostepu%, Postep, Nastepna
        }

        wynik := WprowadzFirme(KasaHwnd, curID, curRabat, Probny)
        if (wynik < 0)
        {
            Blad := StrReplace(OstatniBlad, "`n", " ")
            ; najpierw wracamy w kasie do okna firm (Esc na otwartych oknach kasy)
            Wrocil := PowrotDoFirm(KasaHwnd)
            if (wynik == -3)
            {
                DodajDoRaportu(curID, curRabat, OstZmienioneKart, OstPominiete10, OstPominiete0, "PRZERWANO przez uzytkownika", OstPB, OstZmienione10, OstUwagi)
                Koniec := "PRZERWANO przez uzytkownika na firmie " curID
                break
            }
            stat := (wynik == -2 ? "BRAK KART / NIE ZNALEZIONO FIRMY" : "BLAD") (Wrocil ? " - pominieto" : " - ZATRZYMANO") ": " Blad
            if (OstZmienioneKart > 0)
                stat .= " (zdazono zmienic kart: " OstZmienioneKart ")"
            DodajDoRaportu(curID, curRabat, OstZmienioneKart, OstPominiete10, OstPominiete0, stat, OstPB, OstZmienione10, OstUwagi)
            if (!Wrocil)
            {
                ; blad krytyczny - nie wiadomo, gdzie jestesmy w kasie
                Koniec := "ZATRZYMANO na firmie " curID " - blad krytyczny"
                ZapiszRaport(Koniec)
                Przetwarzanie := false
                SoundBeep, 500, 400
                MsgBox, 16, Zatrzymano, %OstatniBlad%`n`nNie udalo sie wrocic do okna z lista firm, wiec program sie zatrzymal, zeby nic nie wpisac w zle miejsce. Sprawdz okna w kasie.`nSzczegoly: rabaty_log.txt i raport.`nPrzy nastepnym Ctrl+S mozna wznowic od tej firmy.
                return
            }
            if !Probny
                IniWrite, % index + 1, %PlikPostepu%, Postep, Nastepna
            SoundBeep, 500, 300
            tytul := (wynik == -2) ? "Firma bez kart" : "Blad - firma pominieta"
            MsgBox, 262193, %tytul%, Firma %curID%:`n%OstatniBlad%`n`nFirma zostala pominieta i wpisana do raportu.`n`n[OK] = jedz dalej z nastepna firma`n[Anuluj] = zatrzymaj program
            IfMsgBox, Cancel
            {
                Koniec := "PRZERWANO przez uzytkownika po bledzie na firmie " curID
                break
            }
            Aktywuj(KasaHwnd)
            continue
        }
        DodajDoRaportu(curID, curRabat, wynik, OstPominiete10, OstPominiete0, "OK", OstPB, OstZmienione10, OstUwagi)
        TrayTip, Rabaty, Firma %curID%: kart: %wynik%`, pominiete PB/10/0: %OstPB%/%OstPominiete10%/%OstPominiete0%, 2
        if !Probny
            IniWrite, % index + 1, %PlikPostepu%, Postep, Nastepna
    }

    if (InStr(Koniec, "cala lista") && !Probny)
        FileDelete, %PlikPostepu%
    ZapiszRaport(Koniec)
    Przetwarzanie := false

    doSpr := 0
    for i, r in Raport
        if (r.uwaga != "" || (r.status != "OK" && r.status != "pominieta przez uzytkownika"))
            doSpr++
    SoundBeep, 1200, 300
    MsgBox, 64, Koniec, % Koniec "`n`nZmienione karty" (Probny ? " (tryb probny - zmienilby)" : "") ": " LiczbaZmienionych "`nFirmy do sprawdzenia recznie: " doSpr "`n`nZaraz otworzy sie raport."
    Run, % "notepad.exe """ RaportInfo.raport """"
}
