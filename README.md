# rabaty-bot

Program do wprowadzania rabatow w programie kasowym. Gotowy `Rabaty.exe` jest w zakladce **Releases** (budowany automatycznie przy kazdym pushu na `main`).

## Obsluga
1. Uruchom `Rabaty.exe` - pojawi sie komunikat, ze program czuwa w tle (ikona H w zasobniku).
2. Otworz program kasowy i ustaw kursor w polu szukania.
3. **Ctrl + S** - start: wybierz plik `.txt` z rabatami, potwierdz i zatwierdzaj kolejne firmy.
4. **Esc** lub **Ctrl + Q** - natychmiastowe zatrzymanie i zamkniecie programu.

## Format pliku .txt
```
6.49            <- 1. linia: cena na slupie
1001;6.39;10    <- ID;CENA;RABAT
1002;6.29;20
```
Przyklad: `tests/rabaty_test.txt`.
