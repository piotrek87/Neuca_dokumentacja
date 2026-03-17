Dokumentacja w formacie POC (jak POC_NC_1705.docx)
================================================

Zakres: obiekty i pola z pliku Obiekty_i_pola_dokumentacja.xlsx/CSV.
Zrodlo: repozytorium Neuca.Crm.Magellan (tylko odczyt) - model encji + OptionSets.

1. Generowanie
   - Uruchom: .\Generuj-DokumentacjaPOC.ps1
   - Skrypt: odczytuje liste z CSV, typy i opcje z repo (Entities + OptionSets), wypelnia Zrodlo/Opis/Moment (pola systemowe, lookup, reszta "Do uzupelnienia"), zapisuje CSV i od razu generuje .docx.
   - Wynik: Dokumentacja_obiekty_pola_POC.csv oraz Dokumentacja_obiekty_pola_POC.docx (gotowy Word).

2. Kolumny (zgodne z POC)
   Formularz | Nazwa pola | Logiczna nazwa pola | Typ pola | Zrodlo wartosci | Opis logiki | Moment aktualizacji | Uwagi

3. Typ pola w stylu POC
   - Tekst, Lookup, Data i godzina, Waluta, Liczba calkowita/dziesietna, Tak/Nie.
   - Opcje wyboru: "Opcje wyboru - Etykieta1 : wartosc1, Etykieta2 : wartosc2" (z OptionSets.cs).

4. Zrodlo / Opis / Moment
   - Pola systemowe (createdon, modifiedby, ownerid, statuscode, statecode...): opis automatyczny.
   - Lookup: "Wpisane przez uzytkownika (wybor rekordu)", "Zapis rekordu".
   - Reszta: "Do uzupelnienia na podstawie analizy biznesowej (repo: Neuca.Crm.Magellan)" - do uzupelnienia recznie.

5. Opcja -TylkoCSV
   .\Generuj-DokumentacjaPOC.ps1 -TylkoCSV  -- generuje tylko CSV, bez .docx.
