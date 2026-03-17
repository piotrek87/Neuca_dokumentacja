# Zasady pracy nad projektem

Dokument zawiera reguły i ustalenia dotyczące pracy nad projektem **Neuca – Aktualizacja dokumentacji (opis pól)**.

---

## Kontrola wersji (Git)

- Repozytorium: [https://github.com/piotrek87/Neuca_dokumentacja](https://github.com/piotrek87/Neuca_dokumentacja)
- Gałąź główna: `main`
- **Przy każdym commicie** należy:
  - wypisać zmiany w pliku **CHANGELOG.md** z podziałem na dni kalendarzowe,
  - w nawiasie podać, kto dodał zmianę (np. git username).

## Opisy commitów

- Opisy commitów tworzymy zgodnie z **Semantic Release**.
- Zmiany wylistowujemy od myślników, w **języku polskim**.
- Na początku commita umieszczamy identyfikator zadania z Jira (jeśli jest dostępny, np. w nazwie brancha lub podany przez użytkownika).

Przykład:
```
docs: aktualizacja opisu pól WYCENA

- dodanie sekcji opisującej pola X, Y
- poprawka w tabeli Obiekty_i_pola (Jan Kowalski)
```

---

## Struktura projektu

- **CHANGELOG.md** – historia zmian (aktualizowana przy każdym commicie).
- **ZASADY_PRACY.md** – ten dokument (reguły pracy).
- Pozostałe pliki – dokumentacja merytoryczna (CSV, XLSX, MD, DOCX) według potrzeb projektu.

---

## Dodatkowe reguły

*(Miejsce na kolejne ustalenia, np. nazewnictwo plików, recenzje, harmonogramy, kontakt.)*

---

*Ostatnia aktualizacja: 2026-03-13*
