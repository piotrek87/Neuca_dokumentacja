<#
.SYNOPSIS
  Analiza: ktore pola sa na formularzach (solution), w pluginach (repo), w JS (repo).
  Tylko odczyt - zapisuje raport do pliku. Parsowanie formularzy linia po linii (bez pelnego XML).
#>
param(
    [string]$SciezkaCustomizations = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\solution_export\customizations.xml",
    [string]$SciezkaIndeksPluginow = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Indeks_pluginow_encja_pole.csv",
    [string]$SciezkaRepo = "C:\Users\piotr.kowalczyk\source\repos\Neuca.Crm.Magellan",
    [string]$SciezkaRaportu = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Raport_pola_formularz_plugin_js.txt"
)

$ErrorActionPreference = "Stop"
$report = New-Object System.Collections.Generic.List[string]

# ---- 1. Pola na formularzach - parsowanie linia po linii ----
$report.Add("========== POLA NA FORMULARZACH (solution - customizations.xml) ==========")
$report.Add("")

$formPola = @{}  # entity -> hashtable field -> 1
$currentEntity = $null
if (Test-Path $SciezkaCustomizations) {
    $reader = [System.IO.StreamReader]::new($SciezkaCustomizations, [System.Text.Encoding]::UTF8)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            if ($line -match '<entity\s+Name="([^"]+)"') {
                $currentEntity = $Matches[1].Trim()
            }
            if ($line -match 'datafieldname="([^"]+)"') {
                $field = $Matches[1].Trim().ToLowerInvariant()
                if ($currentEntity -and $field) {
                    if (-not $formPola[$currentEntity]) { $formPola[$currentEntity] = @{} }
                    $formPola[$currentEntity][$field] = 1
                }
            }
        }
    } finally { $reader.Close() }
    $totalForm = ($formPola.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    $report.Add("Encje z formularzami: $($formPola.Keys.Count). Lacznie pol na formularzach (unikalne per encja): $totalForm.")
    $report.Add("")
    foreach ($e in ($formPola.Keys | Sort-Object)) {
        $fields = $formPola[$e].Keys | Sort-Object
        $report.Add("  [$e] ($($fields.Count) pol): $($fields -join ', ')")
    }
} else {
    $report.Add("Brak pliku customizations.xml.")
}
$report.Add("")
$report.Add("")

# ---- 2. Pola w pluginach ----
$report.Add("========== POLA W PLUGINACH (repo - Indeks_pluginow_encja_pole.csv) ==========")
$report.Add("")

$pluginPola = @{}
if (Test-Path $SciezkaIndeksPluginow) {
    $idx = Import-Csv -Path $SciezkaIndeksPluginow -Delimiter ";" -Encoding UTF8
    foreach ($r in $idx) {
        $e = $r.EntityLogicalName.Trim().ToLowerInvariant()
        $f = $r.FieldLogicalName.Trim().ToLowerInvariant()
        if ($f -match "enum$") { $f = $f -replace "enum$", "" }
        if (-not $pluginPola[$e]) { $pluginPola[$e] = @{} }
        $pluginPola[$e][$f] = $r.PluginAction
    }
    $totalPlugin = ($pluginPola.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    $report.Add("Encje z pluginami: $($pluginPola.Keys.Count). Lacznie pol w pluginach: $totalPlugin.")
    $report.Add("")
    foreach ($e in ($pluginPola.Keys | Sort-Object)) {
        $list = ($pluginPola[$e].GetEnumerator() | ForEach-Object { "$($_.Key) ($($_.Value))" }) -join "; "
        $report.Add("  [$e] ($($pluginPola[$e].Count) pol): $list")
    }
} else {
    $report.Add("Brak pliku indeksu pluginow.")
}
$report.Add("")
$report.Add("")

# ---- 3. Pola w JavaScript ----
$report.Add("========== POLA W JAVASCRIPT (repo - getAttribute) ==========")
$report.Add("")

$jsRoot = Join-Path $SciezkaRepo "app"
if (-not (Test-Path $jsRoot)) { $jsRoot = $SciezkaRepo }
$jsFiles = Get-ChildItem -Path $jsRoot -Recurse -Filter "*.js" -File | Where-Object { $_.Name -notmatch "\.min\.js$" }
$jsPola = @{}
$jsPolaByEntity = @{}

foreach ($file in $jsFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $matches = [regex]::Matches($content, '\.getAttribute\s*\(\s*["'']([^"'']+)["'']\s*\)')
    $fields = @()
    foreach ($m in $matches) { $fields += $m.Groups[1].Value.Trim().ToLowerInvariant() }
    $fields = $fields | Select-Object -Unique | Sort-Object
    if ($fields.Count -gt 0) {
        $relPath = $file.FullName.Replace($SciezkaRepo, "").TrimStart("\", "/")
        $jsPola[$relPath] = $fields
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $entity = $baseName -replace "_ribbon$", "" -replace "_min$", ""
        if (-not $jsPolaByEntity[$entity]) { $jsPolaByEntity[$entity] = @{} }
        foreach ($f in $fields) { $jsPolaByEntity[$entity][$f] = $relPath }
    }
}

$totalJs = ($jsPola.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
$report.Add("Pliki JS (bez .min) z getAttribute: $($jsPola.Keys.Count). Lacznie odwolan do pol: $totalJs.")
$report.Add("")
$report.Add("-- Per plik:")
foreach ($path in ($jsPola.Keys | Sort-Object)) {
    $report.Add("  $path")
    $report.Add("    pola: $($jsPola[$path] -join ', ')")
}
$report.Add("")
$report.Add("-- Zgrupowane wg encji (z nazwy pliku):")
foreach ($e in ($jsPolaByEntity.Keys | Sort-Object)) {
    $report.Add("  [$e]: $(([array]$jsPolaByEntity[$e].Keys) -join ', ')")
}
$report.Add("")
$report.Add("")

# ---- 4. Podsumowanie ----
$report.Add("========== PODSUMOWANIE ==========")
$report.Add("")
$report.Add("Formularze (solution): $($formPola.Keys.Count) encj, $totalForm pol.")
$report.Add("Pluginy (repo):        $($pluginPola.Keys.Count) encj, $totalPlugin pol.")
$report.Add("JavaScript (repo):     $($jsPola.Keys.Count) plikow, $totalJs odwolan.")
$report.Add("")
$report.Add("Pola tylko w pluginie (brak na formularzu w solution):")
foreach ($e in ($pluginPola.Keys | Sort-Object)) {
    $naFormularzu = if ($formPola[$e]) { $formPola[$e].Keys } else { @() }
    $wPluginie = $pluginPola[$e].Keys
    $tylkoPlugin = $wPluginie | Where-Object { $_ -notin $naFormularzu }
    if ($tylkoPlugin.Count -gt 0) {
        $report.Add("  [$e]: $($tylkoPlugin -join ', ')")
    }
}
$report.Add("")
$report.Add("Pola tylko w JS (brak na formularzu; encja z nazwy pliku):")
foreach ($e in ($jsPolaByEntity.Keys | Sort-Object)) {
    $naFormularzu = if ($formPola[$e]) { $formPola[$e].Keys } else { @() }
    $wJs = $jsPolaByEntity[$e].Keys
    $tylkoJs = $wJs | Where-Object { $_ -notin $naFormularzu }
    if ($tylkoJs.Count -gt 0) {
        $report.Add("  [$e]: $($tylkoJs -join ', ')")
    }
}

$dirR = Split-Path $SciezkaRaportu -Parent
if (-not (Test-Path $dirR)) { New-Item -ItemType Directory -Path $dirR -Force | Out-Null }
$report -join "`r`n" | Out-File -FilePath $SciezkaRaportu -Encoding UTF8
Write-Host "Raport zapisany: $SciezkaRaportu" -ForegroundColor Green
