# rabaty-bot

Program do wprowadzania rabatow w PetrolStationCL. Gotowy `Rabaty.exe` jest w zakladce **Releases** (budowany automatycznie przy kazdym pushu na `main`).

## Klawisze
- **Ctrl + S** - start (wybor pliku .txt)
- **Ctrl + K** - kalibracja pola rabatu (raz, w oknie modyfikacji karty)
- **Esc** / **Ctrl + Q** - natychmiastowe zatrzymanie

## Jak dziala (dla kazdej firmy)
ID, Enter, F10 (lista kart) -> dla kazdej karty: F4, pole rabatu, rabat, F10 (zapis), strzalka w dol.
Program czeka, az kazde okno faktycznie sie otworzy/zamknie. Gdy po strzalce w dol otworzy sie ta sama
karta z nowym rabatem (koniec listy) - Esc, Esc i nastepna firma. Gdy okno sie nie pojawi - program staje.

## Kalibracja (zalecana)
Otworz recznie liste kart (F10), karte (F4), kliknij w pole rabatu i nacisnij **Ctrl + K**.
Program zapamieta okno i pole w `Rabaty.ini` i bedzie od razu wchodzil w to pole (bez Tabow).
Opis okna trafia tez do `diagnostyka.txt`.

## Format pliku .txt
```
6.49            <- 1. linia: cena na slupie
1001;6.39;10    <- ID;CENA;RABAT (grosze)
```

## Ustawienia
`Rabaty.ini` obok programu. Jesli kasa nie nadaza, zwieksz `Tempo` (np. 1.5 albo 2).
