# -*- coding: utf-8 -*-
"""Teksty kolumn dla bloku ekonomicznego [Produkt dopasowany] — opis_pol_przyciskow_akcji_v5.docx."""

from __future__ import annotations

PD = "[Produkt dopasowany]"

OPIS_LOGIKI: dict[str, str] = {}

OPIS_LOGIKI["neu_pricepurchaseunit"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[Ilość sztuk w opakowaniu] <> 0
TO {PD}.[Cena jednostkowa ZACZ] = {PD}.[Cena zakupu ZACZ] / {PD}.[Ilość sztuk w opakowaniu]

JEŻELI kalkulacja {PD}
I {PD}.[Ilość sztuk w opakowaniu] = 0
TO {PD}.[Cena jednostkowa ZACZ] = 0"""

OPIS_LOGIKI["neu_marginbruttopercent"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[Sprzedaż budżetowa oferta] <> 0
TO {PD}.[% Marża brutto] = ( {PD}.[Marża brutto] / {PD}.[Sprzedaż budżetowa oferta] ) * 100

JEŻELI kalkulacja {PD}
I {PD}.[Sprzedaż budżetowa oferta] = 0
TO {PD}.[% Marża brutto] = 0"""

OPIS_LOGIKI["neu_priceselling"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[Kalkulacja z ceną historyczną] = Tak
TO {PD}.[Cena sprzedaży] = {PD}.[Cena historyczna]

JEŻELI kalkulacja {PD}
I {PD}.[Kalkulacja z ceną historyczną] <> Tak
I {PD}.[MW / IR] = Tak
I {PD}.[Cena urzędowa] > 0
I {PD}.[Cena sprzedaży MW / IR] + {PD}.[Korekta narzutu] > {PD}.[Cena urzędowa]
TO {PD}.[Cena sprzedaży] = {PD}.[Cena urzędowa]

JEŻELI kalkulacja {PD}
I {PD}.[Kalkulacja z ceną historyczną] <> Tak
I {PD}.[MW / IR] = Tak
I ( {PD}.[Cena urzędowa] = 0 lub {PD}.[Cena sprzedaży MW / IR] + {PD}.[Korekta narzutu] <= {PD}.[Cena urzędowa] )
TO {PD}.[Cena sprzedaży] = {PD}.[Cena sprzedaży MW / IR] + {PD}.[Korekta narzutu]

JEŻELI kalkulacja {PD}
I {PD}.[Kalkulacja z ceną historyczną] <> Tak
I {PD}.[MW / IR] = Nie
TO {PD}.[Cena sprzedaży] = {PD}.[Cena zakupu po rabatach] * ( 1 + {PD}.[% Narzut] ) + {PD}.[Korekta narzutu]"""

OPIS_LOGIKI["neu_budgetsalebruttosap"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Sprzedaż budżetowa brutto SAP] = {PD}.[Cena sprzedaży brutto] * {PD}.[Ilość jednostek miary SAP]"""

OPIS_LOGIKI["neu_overheadadjustment"] = f"""JEŻELI zapis {PD}
TO {PD}.[Korekta narzutu] = wartość z żądania zapisu

JEŻELI synchronizacja z [Produkt przetargu] na {PD}
TO {PD}.[Korekta narzutu] = [Produkt przetargu].[Korekta narzutu]"""

OPIS_LOGIKI["neu_pricespecialpurchase"] = f"""JEŻELI zapis {PD} ustawia {PD}.[Cena specjalna zakupu ZPZK] przed przeliczeniem pozycji w strukturze przetargu
TO {PD}.[Cena specjalna zakupu ZPZK] = wartość z żądania zapisu

JEŻELI synchronizacja lub import z [ZPZK] albo z [Przetargu] aktualizuje {PD}.[Cena specjalna zakupu ZPZK]
TO {PD}.[Cena specjalna zakupu ZPZK] = wartość z procesu synchronizacji lub importu"""

OPIS_LOGIKI["neu_pricespecialpurchaseunit"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[Ilość sztuk w opakowaniu] <> 0
TO {PD}.[Cena jednostkowa ZPZK] = {PD}.[Cena specjalna zakupu ZPZK] / {PD}.[Ilość sztuk w opakowaniu]

JEŻELI kalkulacja {PD}
I {PD}.[Ilość sztuk w opakowaniu] = 0
TO {PD}.[Cena jednostkowa ZPZK] = 0"""

OPIS_LOGIKI["neu_istradetermssalelimit"] = f"""JEŻELI zapis {PD}
TO {PD}.[Limit twardy] = wartość logiczna z żądania zapisu

JEŻELI synchronizacja z [Produkt przetargu] na {PD}
TO {PD}.[Limit twardy] = [Produkt przetargu].[Limit twardy]"""

OPIS_LOGIKI["neu_budgetsale"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Sprzedaż budżetowa oferta] = {PD}.[Cena sprzedaży] * {PD}.[Ilość jednostek miary do kalkulacji]"""

OPIS_LOGIKI["neu_marginbruttosap"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Marża brutto do SAP] = ( suma czterech składników jak przy {PD}.[Zysk maksymalny], liczonych przy {PD}.[Sprzedaż budżetowa SAP] i {PD}.[Ilość jednostek miary SAP] zamiast sprzedaży oferty i jednostek do kalkulacji ) + {PD}.[Koszt terminu podstawowego] + {PD}.[Koszt terminu opóźnień] + ( szacunkowy koszt odsetkowy od należności brutto (parametry z [Przetarg], wartość brutto i ilość z pozycji): ( [Przetarg].[Roczny koszt kapitału (%)] / 100 ) * [Przetarg].[Oczekiwane opóźnienie] * {PD}.[Cena sprzedaży brutto] * {PD}.[Ilość jednostek miary SAP] )"""

OPIS_LOGIKI["neu_vatrate"] = f"""JEŻELI przygotowanie {PD}
I [Produkt katalogowy] jest wskazany
I [Produkt katalogowy].[VAT (%)] <> puste
TO {PD}.[VAT (%)] = [Produkt katalogowy].[VAT (%)]

JEŻELI przygotowanie {PD}
I [Produkt katalogowy] jest wskazany
I [Produkt katalogowy].[VAT (%)] = puste
TO {PD}.[VAT (%)] = 0%"""

OPIS_LOGIKI["neu_pricepurchaseafterdiscounts"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[MW / IR] = Nie
I {PD}.[Cena specjalna zakupu ZPZK] = 0
I {PD}.[Cena specjalna związana z podwyżką] = 0
TO {PD}.[Cena zakupu po rabatach] = {PD}.[Cena zakupu ZACZ] - {PD}.[Jednostkowa różnica między ceną specjalną a zakupu] - jednostkowe korzyści pozakontraktowe

JEŻELI kalkulacja {PD}
I {PD}.[MW / IR] = Nie
I {PD}.[Cena specjalna zakupu ZPZK] = 0
I {PD}.[Cena specjalna związana z podwyżką] <> 0
TO {PD}.[Cena zakupu po rabatach] = {PD}.[Cena specjalna związana z podwyżką] - {PD}.[Jednostkowa różnica między ceną specjalną a zakupu] - jednostkowe korzyści pozakontraktowe

JEŻELI kalkulacja {PD}
I {PD}.[MW / IR] = Nie
I {PD}.[Cena specjalna zakupu ZPZK] <> 0
TO {PD}.[Cena zakupu po rabatach] = {PD}.[Cena zakupu ZACZ] - {PD}.[Jednostkowa różnica między ceną specjalną a zakupu]

JEŻELI kalkulacja {PD}
I {PD}.[MW / IR] = Tak
I {PD}.[Cena specjalna zakupu ZPZK] <> 0
TO {PD}.[Cena zakupu po rabatach] = {PD}.[Cena specjalna zakupu ZPZK]

JEŻELI kalkulacja {PD}
I {PD}.[MW / IR] = Tak
I {PD}.[Cena specjalna zakupu ZPZK] = 0
I {PD}.[Cena specjalna związana z podwyżką] = 0
TO {PD}.[Cena zakupu po rabatach] = {PD}.[Cena zakupu MW / IR] - {PD}.[Jednostkowa różnica między ceną specjalną a zakupu] - ( {PD}.[% Korzyści do ZACH] * {PD}.[Cena zakupu MW / IR] )

JEŻELI kalkulacja {PD}
I {PD}.[MW / IR] = Tak
I {PD}.[Cena specjalna zakupu ZPZK] = 0
I {PD}.[Cena specjalna związana z podwyżką] <> 0
TO {PD}.[Cena zakupu po rabatach] = {PD}.[Cena specjalna związana z podwyżką] - {PD}.[Jednostkowa różnica między ceną specjalną a zakupu] - jednostkowe korzyści pozakontraktowe"""

OPIS_LOGIKI["neu_pricerss"] = f"""JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[RSS netto] <> puste
TO {PD}.[RSS netto] = [Produkt].[RSS netto]

JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[RSS netto] = puste
TO {PD}.[RSS netto] = 0"""

OPIS_LOGIKI["neu_priceassize"] = f"""JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[Grupa marży] = Urzędówki
I [Produkt].[Cena hurtowa ZCCG] <> puste
TO {PD}.[Cena urzędowa] = [Produkt].[Cena hurtowa ZCCG]

JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I ( [Produkt].[Grupa marży] <> Urzędówki lub [Produkt].[Cena hurtowa ZCCG] = puste )
TO {PD}.[Cena urzędowa] = 0

JEŻELI {PD}.[EAN] <> puste
I istnieje rekord [Ceny urzędowe MZ] z tym samym EAN co {PD}.[EAN]
I [Ceny urzędowe MZ].[Maksymalna cena hurtowa urzędowa] <> puste
TO {PD}.[Cena urzędowa] = [Ceny urzędowe MZ].[Maksymalna cena hurtowa urzędowa]"""

OPIS_LOGIKI["neu_pricetradeafterrise"] = f"""JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[Cena handlowa po maksymalnej podwyżce] <> puste
TO {PD}.[Cena handlowa po podwyżce] = [Produkt].[Cena handlowa po maksymalnej podwyżce]

JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[Cena handlowa po maksymalnej podwyżce] = puste
TO {PD}.[Cena handlowa po podwyżce] = 0"""

OPIS_LOGIKI["neu_budgetsalesap"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Sprzedaż budżetowa SAP] = {PD}.[Cena sprzedaży] * {PD}.[Ilość jednostek miary SAP]"""

OPIS_LOGIKI["neu_unitamount"] = f"""JEŻELI przygotowanie {PD}
I {PD}.[Opakowanie do przeliczeń] = puste
I {PD}.[Ilość jednostek miary rozczytana] <> puste
I {PD}.[Ilość sztuk rozczytana] = pusta
I ( {PD}.[Zmiana ilości] = pusta lub {PD}.[Zmiana ilości] = 0 )
TO {PD}.[Ilość jednostek miary do kalkulacji] = {PD}.[Ilość jednostek miary rozczytana]

JEŻELI przygotowanie {PD}
I {PD}.[Opakowanie do przeliczeń] = puste
I {PD}.[Ilość jednostek miary rozczytana] <> puste
I {PD}.[Ilość sztuk rozczytana] = pusta
I {PD}.[Zmiana ilości] <> 0
TO {PD}.[Ilość jednostek miary do kalkulacji] = {PD}.[Zmiana ilości]

JEŻELI przygotowanie {PD}
I ( {PD}.[Opakowanie do przeliczeń] <> puste lub {PD}.[Ilość jednostek miary rozczytana] = puste lub {PD}.[Ilość sztuk rozczytana] <> pusta )
TO {PD}.[Ilość jednostek miary do kalkulacji] = przeliczenie z {PD}.[Ilość sztuk rozczytana], {PD}.[Opakowanie do przeliczeń], {PD}.[Ilość jednostek miary rozczytana], {PD}.[Sposób przeliczania wielkości opakowań], {PD}.[Zmiana opakowania], {PD}.[Zmiana ilości]"""

OPIS_LOGIKI["neu_priceperunit"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[Wycena za sztukę] = Tak
I {PD}.[Cena sprzedaży] > 0
I {PD}.[Ilość sztuk w opakowaniu] <> 0
TO {PD}.[Cena jednostki miary] = {PD}.[Cena sprzedaży] / {PD}.[Ilość sztuk w opakowaniu] po zaokrągleniu według {PD}.[Sposób przeliczania ceny jednostkowej]

JEŻELI kalkulacja {PD}
I {PD}.[Wycena za sztukę] <> Tak
TO {PD}.[Cena jednostki miary] = 0

JEŻELI kalkulacja {PD}
I {PD}.[Ilość sztuk w opakowaniu] = 0
TO {PD}.[Cena jednostki miary] = 0"""

OPIS_LOGIKI["neu_ispricingperitem"] = f"""JEŻELI zapis {PD} z formularza
TO {PD}.[Wycena za sztukę] = wartość logiczna z formularza sterująca {PD}.[Cena jednostki miary]"""

OPIS_LOGIKI["neu_pricetraderisedate"] = f"""JEŻELI zapis {PD} lub aktualizacja z danych handlowych [Produkt] przy {PD}.[Produkt SAP]
TO {PD}.[Data podwyżki producenta] = data podwyżki ceny handlowej z [Produkt]"""

OPIS_LOGIKI["neu_pricewholesalezccg"] = f"""JEŻELI zapis {PD} lub przeliczenie z danych katalogu
TO {PD}.[Cena hurtowa ZCCG] = cena hurtowa uśredniona ZCCG z [Produkt] przy {PD}.[Produkt SAP]"""

OPIS_LOGIKI["neu_isproducermwir"] = f"""JEŻELI {PD}.[Produkt SAP] jest ustawiony
TO {PD}.[MW / IR] = pole MW / IR na rekordzie [Produkt] wskazywanym przez {PD}.[Produkt SAP] przy pobraniu wartości katalogowych na pozycję

JEŻELI przeliczenie struktury przetargu
TO [Produkt przetargu].[MW / IR] = {PD}.[MW / IR]"""

OPIS_LOGIKI["neu_pricedrugprogramlimit"] = f"""JEŻELI {PD}.[EAN] <> puste
I istnieje rekord [Ceny urzędowe MZ] z tym samym EAN co {PD}.[EAN]
I [Ceny urzędowe MZ].[Limit ceny Programu Lekowego] <> puste
TO {PD}.[Limit ceny Programu Lekowego] = [Ceny urzędowe MZ].[Limit ceny Programu Lekowego]

JEŻELI {PD}.[EAN] <> puste
I istnieje rekord [Ceny urzędowe MZ] z tym samym EAN co {PD}.[EAN]
I [Ceny urzędowe MZ].[Limit ceny Programu Lekowego] = puste
TO {PD}.[Limit ceny Programu Lekowego] = 0"""

OPIS_LOGIKI["neu_pricesellingbrutto"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Cena sprzedaży brutto] = {PD}.[Cena sprzedaży] * ( 1 + {PD}.[VAT (%)] / 100 )"""

OPIS_LOGIKI["neu_pricepurchaseafterriseestimated"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[Cena handlowa ZACH] <> 0
TO {PD}.[Szacowana cena zakupu po podwyżce] = ( {PD}.[Cena zakupu ZACZ] / {PD}.[Cena handlowa ZACH] ) * {PD}.[Cena handlowa po podwyżce]

JEŻELI kalkulacja {PD}
I {PD}.[Cena handlowa ZACH] = 0
TO {PD}.[Szacowana cena zakupu po podwyżce] = 0"""

OPIS_LOGIKI["neu_pricewholesalemaximum"] = f"""JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[Maksymalna cena hurtowa] <> puste
TO {PD}.[Maksymalna cena hurtowa] = [Produkt].[Maksymalna cena hurtowa]

JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[Maksymalna cena hurtowa] = puste
TO {PD}.[Maksymalna cena hurtowa] = 0"""

OPIS_LOGIKI["neu_unitdifferencepricespecialvspurchase"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[Cena specjalna zakupu ZPZK] = 0
TO {PD}.[Jednostkowa różnica między ceną specjalną a zakupu] = 0

JEŻELI kalkulacja {PD}
I {PD}.[Cena specjalna zakupu ZPZK] <> 0
I {PD}.[MW / IR] = Nie
TO {PD}.[Jednostkowa różnica między ceną specjalną a zakupu] = {PD}.[Cena zakupu ZACZ] - {PD}.[Cena specjalna zakupu ZPZK]

JEŻELI kalkulacja {PD}
I {PD}.[Cena specjalna zakupu ZPZK] <> 0
I {PD}.[MW / IR] = Tak
TO {PD}.[Jednostkowa różnica między ceną specjalną a zakupu] = {PD}.[Cena zakupu MW / IR] - {PD}.[Cena specjalna zakupu ZPZK]"""

OPIS_LOGIKI["neu_priceperunitnew"] = f"""JEŻELI inicjalizacja lub brak osobnego procesu ustalającego pole
TO {PD}.[Cena jednostki miary proponowana] = 0

JEŻELI zapis z procesu ustawiającego cenę jednostkową proponowaną
TO {PD}.[Cena jednostki miary proponowana] = wartość z żądania zapisu (nie jest ustawiane w tym samym bloku przypisań co {PD}.[Cena jednostki miary])"""

OPIS_LOGIKI["neu_costzach"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[MW / IR] = Nie
TO {PD}.[Koszt własny ZACH] = - ( {PD}.[Cena handlowa ZACH] * {PD}.[Ilość jednostek miary do kalkulacji] )

JEŻELI kalkulacja {PD}
I {PD}.[MW / IR] = Tak
TO {PD}.[Koszt własny ZACH] = - ( {PD}.[Cena zakupu MW / IR] * {PD}.[Ilość jednostek miary do kalkulacji] )"""

OPIS_LOGIKI["neu_marginbrutto"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Marża brutto] = {PD}.[Zysk maksymalny] + {PD}.[Koszt terminu podstawowego] + {PD}.[Koszt terminu opóźnień] + ( szacunkowy koszt odsetkowy od należności brutto (parametry z [Przetarg], wartość brutto i ilość z pozycji): ( [Przetarg].[Roczny koszt kapitału (%)] / 100 ) * [Przetarg].[Oczekiwane opóźnienie] * {PD}.[Cena sprzedaży brutto] * {PD}.[Ilość jednostek miary do kalkulacji] )"""

OPIS_LOGIKI["neu_stockfinancingpercent"] = f"""JEŻELI zapis {PD} albo przepisanie z [Przetarg]
TO {PD}.[% Finansowanie zapasów] = udział procentowy przeliczany potem na kwotę {PD}.[Finansowanie zapasów] i na {PD}.[Finansowanie zapasów (dni)] przy niezerowej {PD}.[Sprzedaż budżetowa oferta]"""

OPIS_LOGIKI["neu_percentbenefitforzach"] = f"""JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[% Korzyści do ZACH] <> puste
TO {PD}.[% Korzyści do ZACH] = [Produkt].[% Korzyści do ZACH]

JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[% Korzyści do ZACH] = puste
I [Produkt].[Produkt równoważny] <> puste
I [Produkt równoważny].[% Korzyści do ZACH] <> puste
TO {PD}.[% Korzyści do ZACH] = [Produkt równoważny].[% Korzyści do ZACH]

JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[% Korzyści do ZACH] = puste
I [Produkt].[Produkt równoważny] <> puste
I [Produkt równoważny].[% Korzyści do ZACH] = puste
TO {PD}.[% Korzyści do ZACH] = 0

JEŻELI pobranie wartości katalogowych na {PD} przy ustawionym {PD}.[Produkt SAP]
I [Produkt].[% Korzyści do ZACH] = puste
I [Produkt].[Produkt równoważny] = pusty
TO {PD}.[% Korzyści do ZACH] = 0"""

OPIS_LOGIKI["neu_stockfinancing"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Finansowanie zapasów] = wyliczenie z {PD}.[Cena specjalna związana z podwyżką], {PD}.[MW / IR], {PD}.[% Finansowanie zapasów], {PD}.[Cena handlowa ZACH], {PD}.[Ilość jednostek miary do kalkulacji] i {PD}.[Cena zakupu ZACZ] w ujęciu jednostek stosowanych w wariancie SAP pozycji"""

OPIS_LOGIKI["neu_marginadjustmentswithinvoicecontract"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Korekty marży + kontrakt fakturowy] = wyliczenie z {PD}.[Cena specjalna związana z podwyżką], {PD}.[Jednostkowa różnica między ceną specjalną a zakupu], {PD}.[Cena handlowa ZACH], {PD}.[Cena zakupu ZACZ] i {PD}.[Ilość jednostek miary do kalkulacji]"""

OPIS_LOGIKI["neu_stockfinancingdays"] = f"""JEŻELI kalkulacja {PD}
I {PD}.[Sprzedaż budżetowa oferta] <> 0
TO {PD}.[Finansowanie zapasów (dni)] = {PD}.[% Finansowanie zapasów] / ( [Przetarg].[Roczny koszt kapitału (%)] / 100 ) * 365

JEŻELI kalkulacja {PD}
I {PD}.[Sprzedaż budżetowa oferta] = 0
TO {PD}.[Finansowanie zapasów (dni)] = 0"""

OPIS_LOGIKI["neu_noncontractualinvoicebenefits"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Korzyści kontaktowe pozafakturowe] = wyliczenie z {PD}.[Cena specjalna związana z podwyżką], {PD}.[% Korzyści do ZACH], {PD}.[Cena handlowa ZACH], {PD}.[Ilość jednostek miary do kalkulacji] i {PD}.[Cena zakupu ZACZ] według reguł pozycji dla korzyści pozakontraktowych"""

OPIS_LOGIKI["neu_profitonsalemaximum"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Zysk maksymalny] = {PD}.[Marża urzędowo-umowna] + {PD}.[Korzyści kontaktowe pozafakturowe] + {PD}.[Korzyści terminu od dostawcy] + {PD}.[Finansowanie zapasów]"""

OPIS_LOGIKI["neu_margincontractual"] = f"""JEŻELI kalkulacja {PD}
TO {PD}.[Marża urzędowo-umowna] = {PD}.[Sprzedaż budżetowa oferta] + {PD}.[Koszt własny ZACH] + {PD}.[Korekty marży + kontrakt fakturowy]"""


# Sprawdzenie kompletności kluczy względem bloku CSV 438–476
_REQUIRED = (
    "neu_pricepurchaseunit",
    "neu_marginbruttopercent",
    "neu_priceselling",
    "neu_budgetsalebruttosap",
    "neu_overheadadjustment",
    "neu_pricespecialpurchase",
    "neu_pricespecialpurchaseunit",
    "neu_istradetermssalelimit",
    "neu_budgetsale",
    "neu_marginbruttosap",
    "neu_vatrate",
    "neu_pricepurchaseafterdiscounts",
    "neu_pricerss",
    "neu_priceassize",
    "neu_pricetradeafterrise",
    "neu_budgetsalesap",
    "neu_unitamount",
    "neu_priceperunit",
    "neu_ispricingperitem",
    "neu_pricetraderisedate",
    "neu_pricewholesalezccg",
    "neu_isproducermwir",
    "neu_pricedrugprogramlimit",
    "neu_pricesellingbrutto",
    "neu_pricepurchaseafterriseestimated",
    "neu_pricewholesalemaximum",
    "neu_unitdifferencepricespecialvspurchase",
    "neu_priceperunitnew",
    "neu_costzach",
    "neu_marginbrutto",
    "neu_stockfinancingpercent",
    "neu_percentbenefitforzach",
    "neu_stockfinancing",
    "neu_marginadjustmentswithinvoicecontract",
    "neu_stockfinancingdays",
    "neu_noncontractualinvoicebenefits",
    "neu_profitonsalemaximum",
    "neu_margincontractual",
)

for _name in _REQUIRED:
    assert _name in OPIS_LOGIKI, f"Brak OPIS_LOGIKI[{_name}]"

ZRODLO_BLOK = (
    "• Kalkulacja przy przeliczeniu struktury przetargu na rekordzie [Produkt dopasowany], gdy pole jest wynikiem wyliczeń cen i marży na pozycji, w tym z użyciem parametrów z nagłówka [Przetarg] tam, gdzie wchodzą do wzoru (np. finansowe przy odsetkach i terminach)\n\n"
    "• Mapowanie z rekordu [Produkt] lub z [Ceny urzędowe MZ] (w tym dopasowanie po kodzie EAN), gdy wartość jest przepisywana przy przygotowaniu pozycji z katalogu produktów lub z urzędowych cen\n\n"
    "• Zapis użytkownika na formularzu pozycji albo synchronizacja z [Przetarg], [ZPZK] lub [Produkt przetargu], gdy pole jest ustawiane przy zapisie pozycji lub kopiowane z powiązanego rekordu przed dalszym przeliczeniem"
)

MOMENT_BLOK = (
    "• Przeliczenie struktury przetargu na rekordzie [Produkt dopasowany]\n\n"
    "• Zapis rekordu [Produkt dopasowany] po kalkulacji pozycji\n\n"
    "• Synchronizacja z [Produkt przetargu], gdy dotyczy"
)

ZNACZENIE: dict[str, str] = {
    "neu_pricepurchaseunit": "Cena zakupu jednej jednostki użytecznej w podziale przez wielkość opakowania; bazuje do dalszych porównań z cenami specjalnymi i sprzedaży.",
    "neu_marginbruttopercent": "Udział marży brutto w sprzedaży budżetowej oferty; szybka miara rentowności pozycji po przeliczeniu.",
    "neu_priceselling": "Cena sprzedaży netto oferowana przez pozycję: przy cenie historycznej kopiowana jest cena historyczna; przy MW/IR wyliczenie z ceny sprzedaży MW/IR i korekty narzutu, z obcięciem do ceny urzędowej gdy ta jest ustawiona i jest niższa od wyliczenia; poza MW/IR start od zakupu po rabatach z narzutem procentowym i korektą kwotową. Na dalszym kroku mogą nakładać się wyrównania z [Przetarg] (do ceny urzędowej lub do hurtu ZCCG z produktu gdy narzut nie jest z ręki użytkownika) oraz progi z ceny urzędowej, RSS i limitu programu lekowego, żeby cena nie przekraczała dopuszczalnych poziomów przy danym przetargu i pozycji.",
    "neu_budgetsalebruttosap": "Wartość sprzedaży brutto w ujęciu SAP (cena brutto razy jednostki SAP) do porównań z limitami i raportami.",
    "neu_overheadadjustment": "Kwotowa korekta narzutu współdziałająca z procentowym narzutem przy ustalaniu ceny sprzedaży.",
    "neu_pricespecialpurchase": "Cena specjalna zakupu po stronie ZPZK; punkt odniesienia dla różnic jednostkowych i ceny zakupu po rabatach.",
    "neu_pricespecialpurchaseunit": "Cena jednostkowa po specjalnej cenie zakupu ZPZK w podziale przez opakowanie.",
    "neu_istradetermssalelimit": "Informacja, czy przy sprzedaży obowiązuje twardy limit warunków handlowych; wpływa na dalsze wyliczenia i walidacje cen na pozycji.",
    "neu_budgetsale": "Wartość sprzedaży budżetowej oferty jako iloczyn ceny sprzedaży i ilości jednostek do kalkulacji.",
    "neu_marginbruttosap": "Marża brutto po składowych zysku (w wariancie SAP), kosztach terminów oraz szacunkowym koszcie odsetkowym od należności brutto: parametry finansowe z przetargu (roczny koszt kapitału, opóźnienie) mnożone przez cenę sprzedaży brutto i ilość w jednostkach użytych przy rozliczeniu SAP na pozycji.",
    "neu_vatrate": "Stawka VAT pozycji (z produktu katalogowego), potrzebna m.in. do ceny sprzedaży brutto.",
    "neu_pricepurchaseafterdiscounts": "Efektywny poziom zakupu po uwzględnieniu ścieżki ZPZK, MW/IR i różnic jednostkowych — baza pod cenę sprzedaży.",
    "neu_pricerss": "Próg RSS netto na pozycji; razem z ceną urzędową i limitem programu lekowego ogranicza wyliczoną cenę sprzedaży, gdy obowiązują ustawienia programu lekowego na przetargu i pozycji.",
    "neu_priceassize": "Cena urzędowa jednostkowa na pozycji; służy jako odniesienie przy wyrównaniach cen na przetargu i przy progach w programie lekowym.",
    "neu_pricetradeafterrise": "Cena handlowa po podwyżce; wykorzystywana m.in. do szacunku zakupu po podwyżce.",
    "neu_budgetsalesap": "Sprzedaż budżetowa w ujęciu SAP (zaokrąglenie jednostek) przy tej samej cenie sprzedaży.",
    "neu_unitamount": "Ilość jednostek miary używana w iloczynach z cenami i kosztami na pozycji.",
    "neu_priceperunit": "Cena sprzedaży przeliczona na jednostkę miary przy włączonej wycenie za sztukę, z zaokrągleniem wg ustawienia.",
    "neu_ispricingperitem": "Decyduje, czy wyliczać cenę jednostkową z ceny sprzedaży i opakowania.",
    "neu_pricetraderisedate": "Data obowiązywania podwyżki ceny handlowej dla kontekstu cen.",
    "neu_pricewholesalezccg": "Cena hurtowa uśredniona ZCCG z katalogu; przy włączonym wyrównaniu do hurtu na przetargu może zastąpić cenę wyliczoną z narzutu, gdy spełnione są warunki na pozycji i pochodzeniu narzutu.",
    "neu_isproducermwir": "Wybór ścieżki MW/IR zmienia użyte ceny zakupu i marże w kalkulacji.",
    "neu_pricedrugprogramlimit": "Górny limit ceny w programie lekowym na pozycji; obcina wyliczoną cenę sprzedaży, gdy przetarg i produkt są w programie lekowym.",
    "neu_pricesellingbrutto": "Cena sprzedaży z uwzględnieniem VAT, potrzebna do dalszych kwot brutto i odsetek.",
    "neu_pricepurchaseafterriseestimated": "Szacunek ceny zakupu po podwyżce ceny handlowej w relacji do bieżącej ceny handlowej i zakupu.",
    "neu_pricewholesalemaximum": "Górny próg ceny hurtowej z katalogu produktu na pozycji; przy porównaniach z ceną sprzedaży i innymi limitami pokazuje relację do hurtu.",
    "neu_unitdifferencepricespecialvspurchase": "Różnica jednostkowa między ceną specjalną a zakupem; wchodzi do wzoru na cenę zakupu po rabatach.",
    "neu_priceperunitnew": "Propozycja ceny jednostkowej poza bieżącym wyliczeniem głównej ceny jednostkowej (o ile proces ją ustawia).",
    "neu_costzach": "Koszt własny ZACH w ujęciu jednostkowym i ceny handlowej lub zakupu MW/IR.",
    "neu_marginbrutto": "Marża brutto po zysku operacyjnym, kosztach terminów oraz szacunkowym koszcie odsetkowym od należności brutto (jak w polu Przychody odsetkowe: przetarg × cena brutto × ilość do kalkulacji).",
    "neu_stockfinancingpercent": "Udział procentowy finansowania zapasów przekładany na dni i kwotę finansowania.",
    "neu_percentbenefitforzach": "Procent z katalogu [Produkt] (albo z produktu równoważnego, gdy na głównym produkcie pole jest puste), mnożony przy wyliczaniu jednostkowych korzyści pozakontraktowych i ceny zakupu po rabatach na ścieżce MW/IR.",
    "neu_stockfinancing": "Kwota finansowania zapasów z warunków specjalnej ceny, MW/IR i parametrów środowiska.",
    "neu_marginadjustmentswithinvoicecontract": "Korekty marży powiązane z fakturowaniem i kontraktem w relacji do cen specjalnych i handlowej.",
    "neu_stockfinancingdays": "Liczba dni finansowania zapasów wyprowadzona z procentu i parametrów kapitału przy sprzedaży budżetowej.",
    "neu_noncontractualinvoicebenefits": "Korzyści pozafakturowe wyliczane jak korzyści terminu, z udziałem procentu do ZACH.",
    "neu_profitonsalemaximum": "Suma marży umownej, korzyści pozakontraktowych, terminu od dostawcy i finansowania zapasów.",
    "neu_margincontractual": "Marża urzędowo-umowna jako sprzedaż budżetowa powiększona o koszt ZACH i korekty fakturowe.",
}
