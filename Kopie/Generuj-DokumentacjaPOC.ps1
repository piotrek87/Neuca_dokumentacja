<#
.SYNOPSIS
  Generuje dokumentacje w formacie POC (jak POC_NC_1705.docx): obiekty i pola z listy
  Obiekty_i_pola_dokumentacja.csv/xlsx, opisane na podstawie repo Neuca.Crm.Magellan (tylko odczyt).
  Wynik: CSV + gotowy .docx w Kopie. Format POC: Typ pola (z opcjami), Zrodlo wartosci, Opis logiki, Moment aktualizacji.
#>
param(
    [string]$SciezkaRepo = "C:\Users\piotr.kowalczyk\source\repos\Neuca.Crm.Magellan",
    [string]$SciezkaCSV = "C:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Obiekty_i_pola_dokumentacja.csv",
    [string]$SciezkaWyj = "C:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Dokumentacja_obiekty_pola_POC.csv",
    [string]$SciezkaDocx = "C:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Dokumentacja_obiekty_pola_POC.docx",
    [string]$SciezkaIndeksPluginow = "C:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Indeks_pluginow_encja_pole.csv",
    [switch]$TylkoCSV
)

$ErrorActionPreference = "Stop"
$EntitiesPath = Join-Path $SciezkaRepo "app\Neuca.Crm.Magellan.Base\Model\Entities"
$OptionSetsPath = Join-Path $SciezkaRepo "app\Neuca.Crm.Magellan.Base\Model\OptionSets\OptionSets.cs"

# Slownik: nazwa enuma -> lista "label : value" (parsowanie OptionSets.cs - podzial na bloki enum)
$script:OptionSetCache = $null
function PobierzOpcjeZOptionSets {
    if ($null -ne $script:OptionSetCache) { return $script:OptionSetCache }
    $script:OptionSetCache = @{}
    if (-not (Test-Path $OptionSetsPath)) { return $script:OptionSetCache }
    $content = Get-Content $OptionSetsPath -Raw -Encoding UTF8
    $chunks = $content -split 'public enum (\w+)\s*\{'
    for ($i = 1; $i + 1 -lt $chunks.Length; $i += 2) {
        $enumName = $chunks[$i].Trim()
        $block = $chunks[$i + 1]
        $opts = [regex]::Matches($block, 'OptionSetMetadataAttribute\("([^"]+)"[^)]*\)[\s\S]*?\w+\s*=\s*(\d+)')
        $list = @()
        foreach ($m in $opts) { $list += "$($m.Groups[1].Value) : $($m.Groups[2].Value)" }
        if ($list.Count -gt 0) { $script:OptionSetCache[$enumName] = $list }
    }
    return $script:OptionSetCache
}

function Get-OptionSetKey($entity, $field) {
    $f = $field.Trim().ToLowerInvariant()
    if ($f -eq "statuscode") { return "${entity}_StatusCode" }
    if ($f -eq "statecode") { return "${entity}State" }
    return "${entity}_$field"
}

# Szukamy enuma po nazwie encji i pola (np. neu_document_neu_type, neu_document_StatusCode)
function Find-OptionSetForField($entity, $field) {
    $all = PobierzOpcjeZOptionSets
    $key1 = Get-OptionSetKey -entity $entity -field $field
    foreach ($k in $all.Keys) {
        if ($k -eq $key1) { return $all[$k] }
        if ($k.ToLowerInvariant() -eq $key1.ToLowerInvariant()) { return $all[$k] }
    }
    $key2 = "${entity}_$field"
    foreach ($k in $all.Keys) {
        if ($k.ToLowerInvariant() -eq $key2.ToLowerInvariant()) { return $all[$k] }
    }
    return $null
}

# Mapowanie typow C# na opis w stylu POC (z opcjami dla OptionSet)
function MapujTypCSharpNaOpis {
    param([string]$typ, [string]$entity = "", [string]$field = "")
    $t = $typ -replace "System\.Nullable`1\[Microsoft\.Xrm\.Sdk\.(.+)\]", '$1' -replace "System\.Nullable`1\[System\.(.+)\]", '$1'
    $t = $t -replace "Microsoft\.Xrm\.Sdk\.", "" -replace "System\.", ""
    $base = ""
    switch -Regex ($t) {
        "^string$" { $base = "Tekst"; break }
        "^(int|Int32|long|Int64)\??$" { $base = "Liczba calkowita"; break }
        "^(decimal|double|Single)\??$" { $base = "Liczba dziesietna`n- 2 miejsca po przecinku`n- wartosc minimalna: -100 000 000 000`n- wartosc maksymalna: 100 000 000 000"; break }
        "^(DateTime)\??$" { $base = "Data i godzina"; break }
        "^(Guid)\??$" { $base = "Unique identifier (Klucz glowny)"; break }
        "^(Boolean|bool)\??$" { $base = "Tak/Nie"; break }
        "^(EntityReference)$" { $base = "Lookup"; break }
        "^(OptionSetValue)$" {
            $opts = Find-OptionSetForField -entity $entity -field $field
            if ($opts -and $opts.Count -gt 0) { $base = "Opcje wyboru`n" + (($opts | ForEach-Object { "- $_" }) -join "`n") }
            else { $base = "Opcje wyboru" }
            break
        }
        "^(Money)$" { $base = "Waluta"; break }
        "^(EntityCollection)$" { $base = "Kolekcja powiazan"; break }
        "^(Byte\[\]|byte\[\])$" { $base = "Plik / Obraz"; break }
        default { $base = "Tekst" }
    }
    return $base
}

# Z pliku .cs encji wyciagamy slownik: logicalname -> typ C# (z GetAttributeValue<Type> - niezawodne)
function PobierzTypyPolZEntity {
    param([string]$SciezkaPliku)
    if (-not (Test-Path $SciezkaPliku)) { return @{} }
    $content = Get-Content $SciezkaPliku -Raw -Encoding UTF8
    $result = @{}
    $pattern = '\[Microsoft\.Xrm\.Sdk\.AttributeLogicalNameAttribute\("([^"]+)"\)\][\s\S]*?GetAttributeValue<([^>]+)>\(\s*"([^"]+)"\s*\)'
    [void]([regex]::Matches($content, $pattern) | ForEach-Object {
        $name = $_.Groups[1].Value
        $typ = $_.Groups[2].Value.Trim()
        $nameInGet = $_.Groups[3].Value
        if ($name -ne $nameInGet) { return }
        if ($typ -match "Nullable") {
            if ($typ -match "OptionSetValue") { $typ = "OptionSetValue" }
            elseif ($typ -match "DateTime") { $typ = "DateTime?" }
            elseif ($typ -match "Guid") { $typ = "Guid?" }
            elseif ($typ -match "int|Int32") { $typ = "int?" }
            elseif ($typ -match "decimal|double") { $typ = "decimal?" }
            elseif ($typ -match "bool|Boolean") { $typ = "bool?" }
        }
        $result[$name.ToLowerInvariant()] = $typ
    })
    return $result
}

# Indeks: encja|pole -> lista akcji pluginow (z pliku Skanuj-PluginyRepo.ps1)
$script:IndeksPluginow = @{}
function Normalize-FieldForLookup($f) {
    $x = [string]$f.Trim().ToLowerInvariant()
    if ($x -eq "statuscodeenum") { return "statuscode" }
    if ($x -eq "statecode") { return "statecode" }
    if ($x -eq "ownerid") { return "ownerid" }
    if ($x -match "enum$") { return $x -replace "enum$", "" }
    return $x
}
if (Test-Path $SciezkaIndeksPluginow) {
    $idxRows = Import-Csv -Path $SciezkaIndeksPluginow -Delimiter ";" -Encoding UTF8
    foreach ($r in $idxRows) {
        $ent = $r.EntityLogicalName.Trim().ToLowerInvariant()
        $fld = Normalize-FieldForLookup $r.FieldLogicalName
        $key = "${ent}|${fld}"
        if (-not $script:IndeksPluginow[$key]) { $script:IndeksPluginow[$key] = @() }
        $script:IndeksPluginow[$key] += [pscustomobject]@{ PluginAction = $r.PluginAction; SciezkaPliku = $r.SciezkaPliku }
    }
    Write-Host "Zaladowano indeks pluginow: $($script:IndeksPluginow.Keys.Count) kluczy (encja|pole)." -ForegroundColor Gray
}

# Naglowek POC (pola w cudzyslowach, zeby znaki nowej linii w komorkach nie lamaly CSV)
$sep = ";"
function Quote-Csv($v) {
    $s = [string]$v
    return '"' + ($s -replace '"', '""') + '"'
}
$header = (Quote-Csv "Formularz") + $sep + (Quote-Csv "Nazwa pola") + $sep + (Quote-Csv "Logiczna nazwa pola") + $sep + (Quote-Csv "Typ pola") + $sep + (Quote-Csv "Zrodlo wartosci") + $sep + (Quote-Csv "Opis logiki") + $sep + (Quote-Csv "Moment aktualizacji") + $sep + (Quote-Csv "Uwagi")

# Wczytaj liste obiektow i pol z CSV (separator ;)
$wiersze = Import-Csv -Path $SciezkaCSV -Delimiter ";" -Encoding UTF8
$out = New-Object System.Collections.Generic.List[string]
$out.Add($header)

$currentEntity = ""
$typeCache = @{}  # Kod_obiektu -> hashtable logicalname -> typ

foreach ($row in $wiersze) {
    $obiekt = $row.Obiekt
    $kodObiektu = $row.Kod_obiektu
    $nazwaPola = $row.Nazwa_pola
    $idPola = $row.ID_pola

    $formularz = $obiekt
    $logicznaNazwa = if ($idPola) { $idPola } else { "" }
    $typPola = ""
    $zrodlo = ""
    $opisLogiki = ""
    $momentAkt = ""
    $uwagi = ""

    if ($kodObiektu -and $idPola) {
        if ($kodObiektu -ne $currentEntity) {
            $entityFile = Join-Path $EntitiesPath "$kodObiektu.cs"
            $typeCache[$kodObiektu] = PobierzTypyPolZEntity -SciezkaPliku $entityFile
            $currentEntity = $kodObiektu
        }
        $types = $typeCache[$kodObiektu]
        $key = $idPola.Trim().ToLowerInvariant()
        if ($types.ContainsKey($key)) {
            $csharpTyp = $types[$key]
            $typPola = MapujTypCSharpNaOpis -typ $csharpTyp -entity $kodObiektu -field $idPola
            if ($key -in @("statuscode", "statecode") -and ($typPola -eq "Liczba calkowita" -or $typPola -match "brak w modelu")) {
                $opts = Find-OptionSetForField -entity $kodObiektu -field $idPola
                if ($opts -and $opts.Count -gt 0) { $typPola = "Opcje wyboru`n" + (($opts | ForEach-Object { "- $_" }) -join "`n") }
            }
        } else {
            $typPola = "Do uzupelnienia (brak w modelu)"
            if ($idPola -and $key -in @("statuscode", "statecode")) {
                $opts = Find-OptionSetForField -entity $kodObiektu -field $idPola
                if ($opts -and $opts.Count -gt 0) { $typPola = "Opcje wyboru`n" + (($opts | ForEach-Object { "- $_" }) -join "`n") }
            }
        }
    } else {
        $typPola = "Do uzupelnienia"
    }

    # Zrodlo wartosci, Opis logiki, Moment aktualizacji - w stylu POC na podstawie repo (pola systemowe, lookup, reszta do uzupelnienia)
    $idLower = if ($idPola) { $idPola.Trim().ToLowerInvariant() } else { "" }
    $isSystem = $idLower -in @("createdon", "modifiedon", "createdby", "modifiedby", "ownerid", "owningbusinessunit", "owningteam", "owninguser", "statecode", "statuscode", "versionnumber", "overriddencreatedon")
    $isLookup = $typPola -eq "Lookup" -and -not $isSystem
    if ($isSystem) {
        $zrodlo = "Pole systemowe - ustawiane przez platforme D365"
        $opisLogiki = "Wartosc nadawana automatycznie przy utworzeniu lub zapisie rekordu"
        $momentAkt = if ($idLower -eq "createdon" -or $idLower -eq "createdby") { "Utworzenie rekordu" } elseif ($idLower -eq "modifiedon" -or $idLower -eq "modifiedby") { "Zapis rekordu" } else { "Zapis rekordu" }
    } elseif ($isLookup) {
        $zrodlo = "Wpisane przez uzytkownika (wybor rekordu)"
        $opisLogiki = "Pole lookup - powiazanie z innym obiektem w systemie. Do uzupelnienia szczegoly biznesowe (repo: Neuca.Crm.Magellan)."
        $momentAkt = "Zapis rekordu"
    } elseif ($typPola -match "^Opcje wyboru") {
        $zrodlo = "Wybór uzytkownika lub ustawiane wedlug logiki"
        $opisLogiki = "Do uzupelnienia na podstawie analizy biznesowej i konfiguracji (repo: Neuca.Crm.Magellan)."
        $momentAkt = "Zapis rekordu"
    } else {
        $zrodlo = "Do uzupelnienia na podstawie analizy biznesowej (repo: Neuca.Crm.Magellan)"
        $opisLogiki = "Do uzupelnienia na podstawie analizy biznesowej (repo: Neuca.Crm.Magellan)."
        $momentAkt = "Do uzupelnienia"
    }

    # Nadpisanie z indeksu pluginow (repo): Opis logiki i Moment aktualizacji w formacie POC
    if ($kodObiektu -and $idPola -and $script:IndeksPluginow.Count -gt 0) {
        $lookupKey = "$($kodObiektu.Trim().ToLowerInvariant())|$(Normalize-FieldForLookup $idPola)"
        $akcje = $script:IndeksPluginow[$lookupKey]
        if ($akcje -and $akcje.Count -gt 0) {
            $listaAkcji = ($akcje | ForEach-Object { $_.PluginAction }) | Select-Object -Unique
            $zrodlo = "Ustawiane w pluginie (akcje: " + ($listaAkcji -join ", ") + ")"
            $sciezki = @($akcje | ForEach-Object { $_.SciezkaPliku } | Select-Object -Unique)
            $relPath = if ($sciezki.Count -gt 0) { [string]$sciezki[0] } else { "" }
            if ($relPath -and $SciezkaRepo -and $relPath.StartsWith($SciezkaRepo, [StringComparison]::OrdinalIgnoreCase)) {
                $relPath = $relPath.Substring($SciezkaRepo.Length).TrimStart("\", "/")
            }
            $opisLogiki = "Pole ustawiane w pluginie przy zapisie rekordu.`n• Akcje: " + ($listaAkcji -join ", ") + "`nKod (repo): $relPath"
            $momentAkt = "• Zapis rekordu`n" + (($listaAkcji | ForEach-Object { "• Akcja plugin: $_" }) -join "`n")
        }
    }

    $uwagi = $row.Uwagi
    if (-not $uwagi) { $uwagi = "" }

    $line = (Quote-Csv $formularz) + $sep + (Quote-Csv $nazwaPola) + $sep + (Quote-Csv $logicznaNazwa) + $sep + (Quote-Csv $typPola) + $sep + (Quote-Csv $zrodlo) + $sep + (Quote-Csv $opisLogiki) + $sep + (Quote-Csv $momentAkt) + $sep + (Quote-Csv $uwagi)
    $out.Add($line)
}

$dirOut = Split-Path $SciezkaWyj -Parent
if (-not (Test-Path $dirOut)) { New-Item -ItemType Directory -Path $dirOut -Force | Out-Null }
$out | Out-File -FilePath $SciezkaWyj -Encoding UTF8

Write-Host "Zapisano: $SciezkaWyj" -ForegroundColor Green
Write-Host "Liczba wierszy (bez naglowka): $($out.Count - 1). Format POC: typy z opcjami, zrodlo/opis/moment z repo." -ForegroundColor Cyan

if (-not $TylkoCSV -and $SciezkaDocx) {
    $docxScript = Join-Path (Split-Path $SciezkaWyj -Parent) "Generuj-DokumentacjaPOC_Docx.ps1"
    if (Test-Path $docxScript) {
        & $docxScript -SciezkaCSV $SciezkaWyj -SciezkaDocx $SciezkaDocx
    }
}
