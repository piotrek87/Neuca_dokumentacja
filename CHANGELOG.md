# Changelog

## 2026-03-13

- Wypchniecie pelnej dokumentacji i skryptow do zdalnego repo (origin): skrypty w Kopie/, rozszerzona lista CSV/XLSX (13 kolumn), indeks pluginow, solution_export, POC (piotrek87)
- Kolumna Obowiazkowosc w XLSX: trzy poziomy (Obowiazkowe / Opcjonalne / Zwykłe) z customizations.xml RequiredLevel (piotrek87)
- Kolumna Lookup – tabela docelowa: encja docelowa dla pol lookup (ObjectTypeCode + konwencja xxxid), 58 pol (piotrek87)
- Skan calego repo w Skanuj-PluginyRepo.ps1 (nie tylko app): Encja.Fields.pole we wszystkich .cs; faza 2b zmienna.pole w Helpers/Hangfire (piotrek87)
- Skrypt Dodaj-kolumny-formularz-plugin-js.ps1: obowiazkowosc, lookup, formularz, pluginy, JS; wynik 13 kolumn w CSV i XLSX (piotrek87)
- Uspojnienie listy obiektow i pol z systemem: skrypt Dodaj-pola-z-paczki.ps1 czyta paczke solution (tabele_z_dokumentacji_1_0_0_0.zip), parsuje customizations.xml (encje i atrybuty z nazwami PL), porownuje z Obiekty_i_pola_dokumentacja.csv i zapisuje Kopie/Obiekty_i_pola_dokumentacja_rozszerzona.csv z brakujacymi polami (1366 nowych wierszy, razem 2543). Nowe wiersze: W_systemie_D365=tak, Uwagi=Dodane z paczki solution, Nr_4_3=z paczki
- Integracja indeksu pluginow z generatorem POC: Generuj-DokumentacjaPOC.ps1 wczytuje Indeks_pluginow_encja_pole.csv (z Skanuj-PluginyRepo.ps1) i dla pol ustawianych w pluginach uzupelnia kolumny Źródło wartości, Opis logiki, Moment aktualizacji w formacie POC (bulletki •, akcje plugin, sciezka w repo)
- Uruchomienie Skanuj-PluginyRepo.ps1: wygenerowano Indeks_pluginow_encja_pole.csv (22 wpisy encja/pole/akcja)
- Dokumentacja POC (dokonczona): Generuj-DokumentacjaPOC.ps1 generuje CSV + .docx w formacie POC (obiekty/pola z Obiekty_i_pola_dokumentacja.xlsx, zrodlo: repo Neuca.Crm.Magellan). Typ pola z opcjami (OptionSets), Zrodlo/Opis/Moment dla pol systemowych i lookup; statuscode/statecode i inne opcje wyboru z pelna lista etykiet i wartosci
- Połączenie projektu z repozytorium GitHub (https://github.com/piotrek87/Neuca_dokumentacja)
- Inicjalizacja Git, dodanie remote origin, gałąź main
- Dodanie plików dokumentacji i .gitignore
- Utworzenie dokumentu ZASADY_PRACY.md z regułami pracy nad projektem
- Reguła: nie zmieniamy oryginałów, pracujemy na kopiach (folder Kopie); cofanie = powrót do kopii
- Utworzenie folderu Kopie z README
