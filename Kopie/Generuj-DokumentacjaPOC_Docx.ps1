<#
.SYNOPSIS
  Tworzy gotowy plik .docx z tabela dokumentacji POC (OOXML, bez Word COM).
#>
param(
    [string]$SciezkaCSV = "C:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Dokumentacja_obiekty_pola_POC.csv",
    [string]$SciezkaDocx = "C:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Dokumentacja_obiekty_pola_POC.docx"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$baseDir = Split-Path $scriptDir -Parent
if (-not [IO.Path]::IsPathRooted($SciezkaCSV)) { $SciezkaCSV = Join-Path $scriptDir $SciezkaCSV }
if (-not [IO.Path]::IsPathRooted($SciezkaDocx)) { $SciezkaDocx = Join-Path $scriptDir $SciezkaDocx }

if (-not (Test-Path $SciezkaCSV)) {
    Write-Error "Brak pliku CSV. Najpierw uruchom: .\Generuj-DokumentacjaPOC.ps1"
    exit 1
}

function Escape-Xml($t) {
    if ($null -eq $t) { return "" }
    $s = [string]$t
    $s = $s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;'
    return $s
}

# Szerokosci kolumn (dxa): Formularz, Nazwa pola, Logiczna nazwa, Typ pola, Zrodlo, Opis logiki, Moment aktualizacji, Uwagi
$script:ColWidths = @(1800, 2200, 2200, 2000, 2400, 3200, 2600, 1600)

# Komorka w formacie POC: wiele linii = wiele akapitow <w:p> w jednej komorce
function New-Cell($text, [bool]$bold = $false, [int]$colIndex = 0) {
    $lines = [string]$text -split "`r?`n"
    $paras = New-Object System.Collections.Generic.List[string]
    $first = $true
    foreach ($line in $lines) {
        $esc = Escape-Xml $line
        $rPr = if ($bold -and $first) { "<w:rPr><w:b/></w:rPr>" } else { "" }
        $paras.Add("<w:p><w:r>$rPr<w:t>$esc</w:t></w:r></w:p>")
        $first = $false
    }
    if ($paras.Count -eq 0) { $paras.Add("<w:p><w:r><w:t></w:t></w:r></w:p>") }
    $parasJoin = $paras -join ""
    $w = $script:ColWidths[[Math]::Min($colIndex, $script:ColWidths.Count - 1)]
    "<w:tc><w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/></w:tcPr>$parasJoin</w:tc>"
}

function New-Row($cells, [bool]$header = $false) {
    $i = 0
    $cellsXml = ($cells | ForEach-Object { New-Cell $_ -bold $header -colIndex $i; $i++ }) -join ""
    @"
<w:tr>$cellsXml</w:tr>
"@
}

$rows = Import-Csv -Path $SciezkaCSV -Delimiter ";" -Encoding UTF8
$colNames = @("Formularz", "Nazwa pola", "Logiczna nazwa pola", "Typ pola", "Zrodlo wartosci", "Opis logiki", "Moment aktualizacji", "Uwagi")
$headerRow = New-Row $colNames -header $true

$dataRows = New-Object System.Collections.Generic.List[string]
foreach ($row in $rows) {
    $cells = @()
    foreach ($name in $colNames) {
        $val = $row.PSObject.Properties[$name].Value
        if ($null -eq $val) { $cells += "" } else { $cells += [string]$val }
    }
    $dataRows.Add((New-Row $cells))
}
$tableRowsXml = $headerRow + ($dataRows -join "")

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
<w:tbl>
<w:tblPr>
<w:tblW w:w="5000" w:type="pct"/>
<w:tblBorders>
<w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>
<w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>
<w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>
<w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>
<w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>
<w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>
</w:tblBorders>
</w:tblPr>
<w:tblGrid>
<w:gridCol w:w="1800"/><w:gridCol w:w="2200"/><w:gridCol w:w="2200"/><w:gridCol w:w="2000"/>
<w:gridCol w:w="2400"/><w:gridCol w:w="3200"/><w:gridCol w:w="2600"/><w:gridCol w:w="1600"/>
</w:tblGrid>
$tableRowsXml
</w:tbl>
<w:sectPr><w:pgSz w:w="16838" w:h="11906" w:orient="landscape"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr>
</w:body>
</w:document>
"@

$contentTypes = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
"@

$rels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
"@

$docRels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
"@

$styles = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:rPrDefault></w:docDefaults>
</w:styles>
"@

$core = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"><dc:title xmlns:dc="http://purl.org/dc/elements/1.1/">Dokumentacja obiektow i pol - POC</dc:title><dc:creator xmlns:dc="http://purl.org/dc/elements/1.1/">Neuca</dc:creator><dcterms:created xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">2026-01-01T00:00:00Z</dcterms:created></cp:coreProperties>
"@

$app = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Neuca Dokumentacja</Application></Properties>
"@

$tempDir = Join-Path $env:TEMP "DocxPOC_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "word") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "_rels") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "word\_rels") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempDir "docProps") -Force | Out-Null

$documentXml | Out-File -LiteralPath (Join-Path $tempDir "word\document.xml") -Encoding UTF8
$contentTypes | Out-File -LiteralPath (Join-Path $tempDir "[Content_Types].xml") -Encoding UTF8
$rels | Out-File -LiteralPath (Join-Path $tempDir "_rels\.rels") -Encoding UTF8
$docRels | Out-File -LiteralPath (Join-Path $tempDir "word\_rels\document.xml.rels") -Encoding UTF8
$styles | Out-File -LiteralPath (Join-Path $tempDir "word\styles.xml") -Encoding UTF8
$core | Out-File -LiteralPath (Join-Path $tempDir "docProps\core.xml") -Encoding UTF8
$app | Out-File -LiteralPath (Join-Path $tempDir "docProps\app.xml") -Encoding UTF8

if (Test-Path $SciezkaDocx) { Remove-Item $SciezkaDocx -Force }
$zipPath = $SciezkaDocx
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
Remove-Item $tempDir -Recurse -Force

Write-Host "Zapisano: $SciezkaDocx" -ForegroundColor Green
Write-Host "Liczba wierszy w tabeli: 1 naglowek + $($rows.Count) danych." -ForegroundColor Cyan
