# rabaty-bot

Program do wprowadzania rabatow w programie kasowym. Gotowy `Rabaty.exe` jest w zakladce **Releases** (budowany automatycznie przy kazdym pushu na `main`).

## Obsluga
1. Uruchom `Rabaty.exe` - pojawi sie komunikat, ze program czuwa w tle (ikona H w zasobniku).
2. Otworz w programie kasowym okno z lista firm.
3. **Ctrl + S** - start: wybierz plik `.txt` z rabatami, potwierdz i zatwierdzaj kolejne firmy.
   Dla kazdej firmy program robi: ID, Enter, F10 (lista kart), a dla kazdej karty: F4, 5x Tab, rabat, F10 (zapis).
   Po kazdej karcie pyta: Tak = nastepna karta (strzalka w dol), Nie = koniec kart (Esc).
4. **Esc** lub **Ctrl + Q** - natychmiastowe zatrzymanie i zamkniecie programu.

## Format pliku .txt
```
6.49            <- 1. linia: cena na slupie
1001;6.39;10    <- ID;CENA;RABAT
1002;6.29;20;3  <- opcjonalnie 4. pole: liczba kart (wtedy program nie pyta)
```

## Ustawienia
Przy pierwszym uruchomieniu obok programu powstaje `Rabaty.ini`. Jesli kasa nie nadaza, zwieksz `Tempo` (np. 1.5 albo 2). `IloscTab` to liczba Tabow do pola rabatu.
Przyklad: `tests/rabaty_test.txt`.
