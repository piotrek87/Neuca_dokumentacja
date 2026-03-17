<#
.SYNOPSIS
  Konwertuje Obiekty_i_pola_dokumentacja_rozszerzona.csv na .xlsx (Excel).
  Uzywa modulu ImportExcel (dziala bez uruchomionego Excela). Jesli brak modulu - proba przez Excel COM.
#>
param(
    [string]$SciezkaCSV = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Obiekty_i_pola_dokumentacja_rozszerzona.csv",
    [string]$SciezkaXLSX = "c:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Obiekty_i_pola_dokumentacja_rozszerzona.xlsx"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SciezkaCSV)) {
    Write-Error "Brak pliku CSV: $SciezkaCSV"
    exit 1
}

# Preferowana metoda: ImportExcel (Install-Module ImportExcel -Scope CurrentUser)
if (Get-Module -ListAvailable -Name ImportExcel) {
    Write-Host "Wczytuję CSV i zapisuję XLSX (ImportExcel)..." -ForegroundColor Gray
    Import-Module ImportExcel -ErrorAction Stop
    Import-Csv -Path $SciezkaCSV -Delimiter ";" -Encoding UTF8 | Export-Excel -Path $SciezkaXLSX -WorksheetName "Obiekty i pola" -AutoSize -BoldTopRow
    Write-Host "Zapisano: $SciezkaXLSX" -ForegroundColor Green
    exit 0
}

# Fallback: Excel COM
Write-Host "Brak modulu ImportExcel. Uzyj: Install-Module ImportExcel -Scope CurrentUser" -ForegroundColor Yellow
Write-Host "Probuje Excel COM..." -ForegroundColor Gray
$rows = Import-Csv -Path $SciezkaCSV -Delimiter ";" -Encoding UTF8
$colNames = @($rows[0].PSObject.Properties.Name)
$data = New-Object System.Collections.ArrayList
$headerRow = New-Object System.Collections.ArrayList
foreach ($c in $colNames) { [void]$headerRow.Add($c) }
[void]$data.Add($headerRow)
foreach ($r in $rows) {
    $crow = New-Object System.Collections.ArrayList
    foreach ($c in $colNames) {
        $val = $r.PSObject.Properties[$c].Value
        $s = if ($null -eq $val) { "" } else { [string]$val }
        [void]$crow.Add($s)
    }
    [void]$data.Add($crow)
}
$totalRows = $data.Count
$totalCols = $colNames.Count
$excel = $null
try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $wb = $excel.Workbooks.Add()
    $ws = $wb.Worksheets.Item(1)
    $ws.Name = "Obiekty i pola"
    $endCol = [char]([int][char]'A' + $totalCols - 1)
    if ($totalCols -gt 26) { $endCol = "A" + [char]([int][char]'A' + $totalCols - 27) }
    $rangeAddress = "A1:$endCol$totalRows"
    $arr = New-Object 'object[,]' $totalRows, $totalCols
    for ($i = 0; $i -lt $totalRows; $i++) {
        $rowList = $data[$i]
        for ($j = 0; $j -lt $totalCols; $j++) { $arr[$i, $j] = $rowList[$j] }
    }
    $ws.Range($rangeAddress).Value2 = $arr
    $ws.Range("A1:$endCol`1").Font.Bold = $true
    $ws.UsedRange.EntireColumn.AutoFit() | Out-Null
    if (Test-Path $SciezkaXLSX) { Remove-Item $SciezkaXLSX -Force }
    $wb.SaveAs($SciezkaXLSX, 51)
    $wb.Close($false)
    Write-Host "Zapisano: $SciezkaXLSX" -ForegroundColor Green
} finally {
    if ($excel) {
        try { $excel.Quit() } catch { }
        try { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null } catch { }
    }
}
