<#
.SYNOPSIS
  Dodaje do Obiekty_i_pola_dokumentacja_rozszerzona.csv kolumny:
  Obecne na formularzu, Bierze udzial w pluginach, Bierze udzial w js, Obowiazkowosc, Lookup – tabela docelowa.
#>
param(
    [string]$SciezkaCSV = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Obiekty_i_pola_dokumentacja_rozszerzona.csv",
    [string]$SciezkaCustomizations = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\solution_export\customizations.xml",
    [string]$SciezkaIndeksPluginow = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Indeks_pluginow_encja_pole.csv",
    [string]$SciezkaRepo = "C:\Users\piotr.kowalczyk\source\repos\Neuca.Crm.Magellan"
)

$ErrorActionPreference = "Stop"

function Normalize-Field($f) {
    $x = [string]$f.Trim().ToLowerInvariant()
    if ($x -eq "statuscodeenum") { return "statuscode" }
    if ($x -match "enum$") { return $x -replace "enum$", "" }
    return $x
}

function QuoteCsvCell($v) {
    $s = [string]$v
    if ($null -eq $v) { $s = "" }
    if ($s -match '[";\r\n]') { return "`"$($s -replace '`"','""')`"" }
    return $s
}

# ---- Wczytaj liste ----
$lista = Import-Csv -Path $SciezkaCSV -Delimiter ";" -Encoding UTF8
Write-Host "Wierszy w liscie: $($lista.Count)" -ForegroundColor Gray

# ---- 1. Pola na formularzach (customizations) ----
$formSet = @{}  # entity -> hashtable field->1
$currentEntity = $null
if (Test-Path $SciezkaCustomizations) {
    $reader = [System.IO.StreamReader]::new($SciezkaCustomizations, [System.Text.Encoding]::UTF8)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            if ($line -match '<entity\s+Name="([^"]+)"') { $currentEntity = $Matches[1].Trim().ToLowerInvariant() }
            if ($line -match 'datafieldname="([^"]+)"') {
                $field = $Matches[1].Trim().ToLowerInvariant()
                if ($currentEntity -and $field) {
                    if (-not $formSet[$currentEntity]) { $formSet[$currentEntity] = @{} }
                    $formSet[$currentEntity][$field] = 1
                }
            }
        }
    } finally { $reader.Close() }
    $totalForm = ($formSet.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    Write-Host "Formularze: $($formSet.Keys.Count) encj, $totalForm pol." -ForegroundColor Gray
} else {
    Write-Host "Brak customizations.xml." -ForegroundColor Yellow
}

# ---- 1b. Obowiazkowosc i Lookup – tabela docelowa (z customizations) ----
$requiredLevelSet = @{}   # "entity|field" -> "Obowiązkowe" | "Opcjonalne" | "Zwykłe"
$lookupTargetSet = @{}    # "entity|field" -> "entityname" lub "entity1, entity2"
# Znane kody encji systemowych D365 (nie zawsze w eksporcie solution)
$objectTypeToEntity = @{
    "1" = "account"; "2" = "contact"; "3" = "lead"; "4" = "opportunity"; "5" = "task"; "7" = "letter"
    "8" = "systemuser"; "9" = "team"; "10" = "businessunit"; "12" = "activitypointer"; "14" = "principal"
    "16" = "queue"; "18" = "queueitem"; "20" = "email"; "22" = "appointment"; "24" = "campaign"
    "25" = "campaignactivity"; "26" = "campaignresponse"; "27" = "list"; "29" = "product"
    "30" = "invoice"; "31" = "invoicedetail"; "32" = "salesorder"; "33" = "salesorderdetail"
    "35" = "competitor"; "36" = "opportunityproduct"; "37" = "quote"; "38" = "quotedetail"
    "112" = "incident"; "115" = "knowledgearticle"; "127" = "contract"; "4200" = "activity"
    "4201" = "appointment"; "4202" = "email"; "4210" = "fax"; "4212" = "letter"; "4214" = "phonecall"
    "4216" = "task"; "4220" = "socialactivity"; "4230" = "recurringappointmentmaster"
}
if (Test-Path $SciezkaCustomizations) {
    # Pass 1: zbuduj mape ObjectTypeCode -> encja (wszystkie encje w pliku, nadpisuja domyslne)
    $reader1 = [System.IO.StreamReader]::new($SciezkaCustomizations, [System.Text.Encoding]::UTF8)
    try {
        $currentOTC = $null
        while ($null -ne ($line = $reader1.ReadLine())) {
            if ($line -match '<ObjectTypeCode>(\d+)</ObjectTypeCode>') { $currentOTC = $Matches[1] }
            if ($line -match '<entity\s+Name="([^"]+)"') {
                $en = $Matches[1].Trim().ToLowerInvariant()
                if ($currentOTC) { $objectTypeToEntity[$currentOTC] = $en }
            }
        }
    } finally { $reader1.Close() }
    # Pass 2: atrybuty – RequiredLevel i Lookup (LookupType -> encja z mapy)
    $currentEntity = $null
    $inAttribute = $false
    $curAttrLogical = $null
    $curAttrRequired = $null
    $curAttrType = $null
    $curAttrLookupCodes = @()
    $reader2 = [System.IO.StreamReader]::new($SciezkaCustomizations, [System.Text.Encoding]::UTF8)
    try {
        while ($null -ne ($line = $reader2.ReadLine())) {
            if ($line -match '<entity\s+Name="([^"]+)"') { $currentEntity = $Matches[1].Trim().ToLowerInvariant() }
            if ($line -match '<attribute\s+PhysicalName=') {
                $inAttribute = $true
                $curAttrLogical = $null; $curAttrRequired = $null; $curAttrType = $null; $curAttrLookupCodes = @()
            }
            if ($inAttribute) {
                if ($line -match '<LogicalName>([^<]+)</LogicalName>') { $curAttrLogical = $Matches[1].Trim().ToLowerInvariant() }
                if ($line -match '<RequiredLevel>([^<]+)</RequiredLevel>') { $curAttrRequired = $Matches[1].Trim().ToLowerInvariant() }
                if ($line -match '<Type>([^<]+)</Type>') { $curAttrType = $Matches[1].Trim().ToLowerInvariant() }
                if ($line -match '<LookupType[^>]*>(\d+)</LookupType>') { $curAttrLookupCodes += $Matches[1] }
            }
            if ($line -match '</attribute>') {
                if ($inAttribute -and $currentEntity -and $curAttrLogical) {
                    if ($curAttrRequired) {
                        $req = $curAttrRequired
                        if ($req -eq "systemrequired" -or $req -eq "applicationrequired") { $requiredLevelSet["${currentEntity}|${curAttrLogical}"] = "Obowiązkowe" }
                        elseif ($req -eq "recommended") { $requiredLevelSet["${currentEntity}|${curAttrLogical}"] = "Opcjonalne" }
                        elseif ($req -eq "none") { $requiredLevelSet["${currentEntity}|${curAttrLogical}"] = "Zwykłe" }
                        else { $requiredLevelSet["${currentEntity}|${curAttrLogical}"] = $req }
                    }
                    if ($curAttrType -eq "lookup") {
                        $targets = @()
                        if ($curAttrLookupCodes.Count -gt 0) {
                            foreach ($code in $curAttrLookupCodes) {
                                if ($objectTypeToEntity[$code]) { $targets += $objectTypeToEntity[$code] }
                            }
                        }
                        if ($targets.Count -eq 0 -and $curAttrLogical -match '^(.+)id$') {
                            $refCandidate = $Matches[1]
                            if ($objectTypeToEntity.Values -contains $refCandidate) { $targets += $refCandidate }
                        }
                        if ($targets.Count -gt 0) { $lookupTargetSet["${currentEntity}|${curAttrLogical}"] = ($targets | Select-Object -Unique) -join ", " }
                    }
                }
                $inAttribute = $false
            }
        }
    } finally { $reader2.Close() }
    Write-Host "Obowiazkowosc: $($requiredLevelSet.Keys.Count) pol; Lookup (tabela docelowa): $($lookupTargetSet.Keys.Count) pol." -ForegroundColor Gray
}

# ---- 2. Pluginy (indeks) ----
$pluginLookup = @{}  # "entity|field" -> @(action1, action2)
if (Test-Path $SciezkaIndeksPluginow) {
    try {
        $idx = Import-Csv -Path $SciezkaIndeksPluginow -Delimiter ";" -Encoding UTF8
        foreach ($r in $idx) {
            $e = [string]$r.EntityLogicalName
            if (-not $e) { continue }
            $e = $e.Trim().ToLowerInvariant()
            $f = Normalize-Field ([string]$r.FieldLogicalName)
            $key = "${e}|${f}"
            if (-not $pluginLookup[$key]) { $pluginLookup[$key] = @() }
            $pluginLookup[$key] += [string]$r.PluginAction
        }
        foreach ($k in @($pluginLookup.Keys)) { $pluginLookup[$k] = @($pluginLookup[$k] | Select-Object -Unique) }
        Write-Host "Pluginy: $($pluginLookup.Keys.Count) par encja|pole." -ForegroundColor Gray
    } catch {
        Write-Host "Uwaga: blad wczytywania indeksu pluginow: $_" -ForegroundColor Yellow
    }
}

# ---- 3. JavaScript (getAttribute) ----
$jsLookup = @{}  # "entity|field" -> @("file1.js", "file2.js")
$jsRoot = Join-Path $SciezkaRepo "app"
if (-not (Test-Path $jsRoot)) { $jsRoot = $SciezkaRepo }
# Ogranicz do WebResources (skrypty formularzy / ribbon) - szybsze i mniej szumu
$wrPath = Join-Path $jsRoot "Neuca.Crm.Magellan.WebResources"
if (Test-Path $wrPath) { $jsRoot = $wrPath }
$jsFiles = Get-ChildItem -Path $jsRoot -Recurse -Filter "*.js" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "\.min\.js$" }
foreach ($file in $jsFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $matches = [regex]::Matches($content, '\.getAttribute\s*\(\s*["'']([^"'']+)["'']\s*\)')
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $entity = $baseName.Trim().ToLowerInvariant()
    $shortName = $file.Name
    foreach ($m in $matches) {
        $field = $m.Groups[1].Value.Trim().ToLowerInvariant()
        if ($field -match "^(class|id|type|value|href|lang|disabled|xml:lang|classname|src|role|title|data-|params|open|innerhtml|checked|selected|readonly|ng-|aria-|x-placement)$") { continue }
        $key = "${entity}|${field}"
        if (-not $jsLookup[$key]) { $jsLookup[$key] = @{} }
        $jsLookup[$key][$shortName] = 1
    }
}
foreach ($k in @($jsLookup.Keys)) { $jsLookup[$k] = @($jsLookup[$k].Keys) }
Write-Host "JavaScript: $($jsLookup.Keys.Count) par encja|pole (z nazwy pliku)." -ForegroundColor Gray

# ---- Wypelnij kolumny dla kazdego wiersza ----
$sep = ";"
$colNames = @("Obiekt", "Kod_obiektu", "Nr_4_3", "Nazwa_pola", "ID_pola", "Lp_pola_w_obiekcie", "W_systemie_D365", "Uwagi", "Obecne na formularzu", "Bierze udzial w pluginach", "Bierze udzial w js", "Obowiazkowosc", "Lookup – tabela docelowa")
$out = New-Object System.Collections.Generic.List[string]
$out.Add($colNames -join $sep)

foreach ($r in $lista) {
    $kod = [string]$r.Kod_obiektu
    $idPola = [string]$r.ID_pola
    $kodL = $kod.Trim().ToLowerInvariant()
    $idL = $idPola.Trim().ToLowerInvariant()
    $idNorm = Normalize-Field $idPola

    $naForm = "nie"
    if ($kodL -and $idL -and $formSet[$kodL] -and $formSet[$kodL][$idL]) { $naForm = "tak" }

    $pluginy = ""
    $keyP = "${kodL}|${idNorm}"
    if ($pluginLookup[$keyP]) { $pluginy = ($pluginLookup[$keyP] | Sort-Object) -join ", " }

    $jsFiles = ""
    $keyJ = "${kodL}|${idL}"
    if ($jsLookup[$keyJ]) { $jsFiles = ($jsLookup[$keyJ] | Sort-Object) -join ", " }

    $obow = ""
    $keyReq = "${kodL}|${idL}"
    if ($requiredLevelSet[$keyReq]) { $obow = $requiredLevelSet[$keyReq] }

    $lookupTabela = ""
    if ($lookupTargetSet[$keyReq]) { $lookupTabela = $lookupTargetSet[$keyReq] }

    $cells = @()
    foreach ($c in @("Obiekt", "Kod_obiektu", "Nr_4_3", "Nazwa_pola", "ID_pola", "Lp_pola_w_obiekcie", "W_systemie_D365", "Uwagi")) {
        $cells += QuoteCsvCell($r.$c)
    }
    $cells += QuoteCsvCell($naForm)
    $cells += QuoteCsvCell($pluginy)
    $cells += QuoteCsvCell($jsFiles)
    $cells += QuoteCsvCell($obow)
    $cells += QuoteCsvCell($lookupTabela)
    $out.Add($cells -join $sep)
}

$out | Out-File -FilePath $SciezkaCSV -Encoding UTF8
Write-Host "Zapisano: $SciezkaCSV (13 kolumn)." -ForegroundColor Green
