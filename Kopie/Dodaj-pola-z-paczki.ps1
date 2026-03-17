<#
.SYNOPSIS
  Czyta paczke solution (customizations.xml), porownuje z lista Obiekty_i_pola_dokumentacja
  i zapisuje rozszerzona liste z brakujacymi polami (encje/atrybuty z systemu).
#>
param(
    [string]$SciezkaPaczki = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\tabele_z_dokumentacji_1_0_0_0.zip",
    [string]$SciezkaListy = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Obiekty_i_pola_dokumentacja.csv",
    [string]$SciezkaWyj = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Obiekty_i_pola_dokumentacja_rozszerzona.csv",
    [string]$SciezkaKopie = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie"
)

$ErrorActionPreference = "Stop"

# Rozpakuj paczke jesli trzeba
$zipDir = Join-Path $SciezkaKopie "solution_export"
$customPath = Join-Path $zipDir "customizations.xml"
if (-not (Test-Path $customPath)) {
    if (-not (Test-Path $SciezkaPaczki)) {
        Write-Error "Brak paczki: $SciezkaPaczki oraz brak rozpakowanego customizations.xml w $zipDir"
        exit 1
    }
    Write-Host "Rozpakowuję paczkę..." -ForegroundColor Gray
    Expand-Archive -Path $SciezkaPaczki -DestinationPath $zipDir -Force
}

if (-not (Test-Path $customPath)) {
    Write-Error "Brak pliku customizations.xml w $zipDir"
    exit 1
}

# Wczytaj obecna liste
$lista = Import-Csv -Path $SciezkaListy -Delimiter ";" -Encoding UTF8
$obecneKlucze = @{}
foreach ($r in $lista) {
    $kod = [string]$r.Kod_obiektu
    $idPola = [string]$r.ID_pola
    if ($kod -and $idPola) {
        $key = "$($kod.Trim().ToLowerInvariant())|$($idPola.Trim().ToLowerInvariant())"
        $obecneKlucze[$key] = $true
    }
}
Write-Host "W liscie dokumentacji: $($lista.Count) wierszy, $($obecneKlucze.Count) unikalnych par (obiekt|pole)." -ForegroundColor Gray

# Maksymalne Lp per obiekt (do numeracji nowych pol)
$maxLp = @{}
foreach ($r in $lista) {
    $kod = [string]$r.Kod_obiektu
    if (-not $kod) { continue }
    $lp = 0
    if ($r.'Lp_pola_w_obiekcie' -match '^\d+$') { $lp = [int]$r.'Lp_pola_w_obiekcie' }
    if (-not $maxLp[$kod] -or $maxLp[$kod] -lt $lp) { $maxLp[$kod] = $lp }
}

# Parsowanie customizations.xml (duzy plik - uzywamy [xml])
Write-Host "Wczytuję customizations.xml (może chwilę potrwać)..." -ForegroundColor Gray
[xml]$xml = Get-Content -Path $customPath -Encoding UTF8

$ns = @{ d = $xml.DocumentElement.NamespaceURI }
if (-not $ns.d) { $ns.d = "" }

$entities = $xml.ImportExportXml.Entities.Entity
$brakujace = New-Object System.Collections.Generic.List[object]
$liczbaEncji = 0
$liczbaAtrybutow = 0

foreach ($ent in $entities) {
    $entNameNode = $ent.Name
    $entLogical = $ent.EntityInfo.entity.Name
    if (-not $entLogical) { $entLogical = $entNameNode.InnerText.Trim() }
    $entDisplay = $entNameNode.LocalizedName
    if (-not $entDisplay) {
        $loc = $ent.EntityInfo.entity.LocalizedNames.LocalizedName | Where-Object { $_.languagecode -eq "1045" } | Select-Object -First 1
        if ($loc) { $entDisplay = $loc.description }
    }
    if (-not $entDisplay) { $entDisplay = $entLogical }

    $attrs = $ent.EntityInfo.entity.attributes.attribute
    if (-not $attrs) { continue }
    $liczbaEncji++
    $lp = $maxLp[$entLogical]
    if (-not $lp) { $lp = 0 }

    foreach ($attr in $attrs) {
        $liczbaAtrybutow++
        $attrLogical = [string]$attr.LogicalName
        if (-not $attrLogical) { continue }
        $dispNodes = $attr.displaynames.displayname | Where-Object { $_.languagecode -eq "1045" }
        $attrDisplay = ""
        if ($dispNodes) { $attrDisplay = $dispNodes[0].description }
        if (-not $attrDisplay) { $attrDisplay = $attrLogical }

        $key = "$($entLogical.Trim().ToLowerInvariant())|$($attrLogical.Trim().ToLowerInvariant())"
        if ($obecneKlucze[$key]) { continue }
        # Pomijamy pola *_base (wartość w walucie bazowej) – do analiz/raportów, nie do dokumentacji formularzy
        if ($attrLogical.Trim().EndsWith("_base")) { continue }

        $lp++
        $brakujace.Add([pscustomobject]@{
            Obiekt                = $entDisplay
            Kod_obiektu           = $entLogical
            Nr_4_3                = "z paczki"
            Nazwa_pola            = $attrDisplay
            ID_pola               = $attrLogical
            Lp_pola_w_obiekcie    = $lp
            W_systemie_D365       = "tak"
            Uwagi                 = "Dodane z paczki solution (tabele_z_dokumentacji)"
        })
        $obecneKlucze[$key] = $true
    }
    $maxLp[$entLogical] = $lp
}

Write-Host "Z paczki: encje z atrybutami przetworzone. Brakujących w dokumentacji: $($brakujace.Count) pól." -ForegroundColor Cyan

# Scal: oryginalna lista + brakujace (nowe)
$sep = ";"
$naglowek = "Obiekt;Kod_obiektu;Nr_4_3;Nazwa_pola;ID_pola;Lp_pola_w_obiekcie;W_systemie_D365;Uwagi"
$out = New-Object System.Collections.Generic.List[string]
$out.Add($naglowek)

function QuoteCsvCell($v) {
    $s = [string]$v
    if ($null -eq $v) { $s = "" }
    if ($s -match '[";\r\n]') { return "`"$($s -replace '`"','""')`"" }
    return $s
}

$colNames = @("Obiekt", "Kod_obiektu", "Nr_4_3", "Nazwa_pola", "ID_pola", "Lp_pola_w_obiekcie", "W_systemie_D365", "Uwagi")
foreach ($r in $lista) {
    $cells = @()
    foreach ($c in $colNames) { $cells += QuoteCsvCell($r.$c) }
    $out.Add($cells -join $sep)
}

foreach ($r in $brakujace) {
    $cells = @(
        (QuoteCsvCell $r.Obiekt),
        (QuoteCsvCell $r.Kod_obiektu),
        (QuoteCsvCell $r.Nr_4_3),
        (QuoteCsvCell $r.Nazwa_pola),
        (QuoteCsvCell $r.ID_pola),
        (QuoteCsvCell $r.Lp_pola_w_obiekcie),
        (QuoteCsvCell $r.W_systemie_D365),
        (QuoteCsvCell $r.Uwagi)
    )
    $out.Add($cells -join $sep)
}

$dirOut = Split-Path $SciezkaWyj -Parent
if (-not (Test-Path $dirOut)) { New-Item -ItemType Directory -Path $dirOut -Force | Out-Null }
$out | Out-File -FilePath $SciezkaWyj -Encoding UTF8

Write-Host "Zapisano: $SciezkaWyj" -ForegroundColor Green
Write-Host "Razem wierszy: $($out.Count - 1) (oryginalne: $($lista.Count), dodane z paczki: $($brakujace.Count))." -ForegroundColor Cyan
