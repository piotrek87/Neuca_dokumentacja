<#
.SYNOPSIS
  Skanuje repo Neuca.Crm.Magellan (app/plugins) i buduje indeks: ktore encje i pola sa ustawiane w jakich akcjach.
  Wynik: Kopie/Indeks_pluginow_encja_pole.csv (EntityLogicalName;FieldLogicalName;PluginAction;SciezkaPliku)
  Uzywane przez Generuj-DokumentacjaPOC.ps1 do uzupelnienia Opis logiki i Moment aktualizacji.
#>
param(
    [string]$SciezkaRepo = "C:\Users\piotr.kowalczyk\source\repos\Neuca.Crm.Magellan",
    [string]$SciezkaWyj = "C:\Users\piotr.kowalczyk\OneDrive - xentivo.pl\Desktop\Neuca\Aktualizacja dokumentacji - opis pól\Kopie\Indeks_pluginow_encja_pole.csv"
)

$ErrorActionPreference = "Stop"
$pluginsDir = Join-Path $SciezkaRepo "app\plugins"
$entitiesDir = Join-Path $SciezkaRepo "app\Neuca.Crm.Magellan.Base\Model\Entities"

# Mapowanie nazwy typu C# na logical name (dla typow bez pliku w Entities lub standardowych)
$typeToLogical = @{
    "Opportunity" = "opportunity"
    "Account" = "account"
    "Contact" = "contact"
    "Lead" = "lead"
    "Task" = "task"
    "SystemUser" = "systemuser"
    "Product" = "product"
    "Email" = "email"
    "Connection" = "connection"
    "SalesOrderDetail" = "salesorderdetail"
    "QueueItem" = "queueitem"
    "SLAKPIInstance" = "slakpiinstance"
}

function Get-EntityLogicalName {
    param([string]$typeName)
    if ($typeToLogical.ContainsKey($typeName)) { return $typeToLogical[$typeName] }
    if ($typeName -match "^neu_") { return $typeName }
    $entityFile = Join-Path $entitiesDir "$typeName.cs"
    if (Test-Path $entityFile) {
        $c = Get-Content $entityFile -Raw -Encoding UTF8
        if ($c -match 'EntityLogicalName\s*=\s*"([^"]+)"') { return $Matches[1] }
    }
    return $typeName.ToLowerInvariant()
}

function To-FieldLogicalName {
    param([string]$propName)
    if (-not $propName) { return "" }
    if ($propName -match "^neu_") { return $propName }
    return $propName.Substring(0,1).ToLowerInvariant() + $propName.Substring(1)
}

$results = @()
$actionFiles = Get-ChildItem -Path $pluginsDir -Filter "*.cs" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "Actions?\\[^\\]+\.cs$" }
foreach ($file in $actionFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $className = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $entityTypes = [regex]::Matches($content, 'GetTargetEntity<(\w+)>\s*\(\)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    foreach ($et in $entityTypes) {
        $entityLogical = Get-EntityLogicalName -typeName $et
        $seen = @{}
        # Pola z SetAttributeValue("...")
        $fields = [regex]::Matches($content, 'SetAttributeValue\s*\(\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        foreach ($f in $fields) {
            $key = $f.Trim().ToLowerInvariant()
            if (-not $seen[$key]) { $seen[$key] = $true; $results += [pscustomobject]@{ EntityLogicalName = $entityLogical; FieldLogicalName = $f; PluginAction = $className; SciezkaPliku = $file.FullName } }
        }
        # Pola z GetTargetEntity<T>().Wlasciwosc (dowolne uzycie: odczyt .Prop lub zapis .Prop =)
        $propMatches = [regex]::Matches($content, 'GetTargetEntity<' + [regex]::Escape($et) + '>\s*\(\)\s*\.\s*(\w+)\b') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        foreach ($prop in $propMatches) {
            $fieldLogical = To-FieldLogicalName $prop
            $key = $fieldLogical.Trim().ToLowerInvariant()
            if (-not $seen[$key]) { $seen[$key] = $true; $results += [pscustomobject]@{ EntityLogicalName = $entityLogical; FieldLogicalName = $fieldLogical; PluginAction = $className; SciezkaPliku = $file.FullName } }
        }
        # EncjaTyp.Fields.NazwaPola (np. Opportunity.Fields.neu_clientid)
        $fieldsRefs = [regex]::Matches($content, [regex]::Escape($et) + '\.Fields\.(\w+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        foreach ($f in $fieldsRefs) {
            $fieldLogical = To-FieldLogicalName $f
            $key = $fieldLogical.Trim().ToLowerInvariant()
            if (-not $seen[$key]) { $seen[$key] = $true; $results += [pscustomobject]@{ EntityLogicalName = $entityLogical; FieldLogicalName = $fieldLogical; PluginAction = $className; SciezkaPliku = $file.FullName } }
        }
    }

    # GetAttributeValue<...>(EntityType.Fields.xxx) - encja z kontekstu (moze byc inna niz GetTargetEntity w pliku)
    [regex]::Matches($content, 'GetAttributeValue\s*<[^>]+>\s*\(\s*(\w+)\.Fields\.(\w+)\)') | ForEach-Object {
        $entType = $_.Groups[1].Value
        $fld = $_.Groups[2].Value
        $entLogical = Get-EntityLogicalName -typeName $entType
        $fieldLogical = To-FieldLogicalName $fld
        $results += [pscustomobject]@{ EntityLogicalName = $entLogical; FieldLogicalName = $fieldLogical; PluginAction = $className; SciezkaPliku = $file.FullName }
    }
}

# Faza 2: caly repo - szukaj EncjaTyp.Fields.pole we wszystkich .cs (bez tests, obj, bin, packages)
$typeToLogical["SalesOrder"] = "salesorder"
$typeToLogical["neu_quote"] = "neu_quote"
$typeToLogical["neu_quotebundle"] = "neu_quotebundle"
$typeToLogical["neu_tenderbundle"] = "neu_tenderbundle"
$typeToLogical["neu_tenderproduct"] = "neu_tenderproduct"
$typeToLogical["neu_mappedproduct"] = "neu_mappedproduct"
$typeToLogical["neu_tradeterms"] = "neu_tradeterms"
$typeToLogical["neu_producer"] = "neu_producer"
$typeToLogical["neu_packagemissing"] = "neu_packagemissing"
$typeToLogical["neu_offerasset"] = "neu_offerasset"
$typeToLogical["neu_note_sales"] = "neu_note_sales"
$typeToLogical["neu_indicator"] = "neu_indicator"
$typeToLogical["neu_sdpermission"] = "neu_sdpermission"
$typeToLogical["neu_contract"] = "neu_contract"
$typeToLogical["neu_competitorsanalysis"] = "neu_competitorsanalysis"
$typeToLogical["neu_client"] = "neu_client"
$typeToLogical["neu_conf_operationmanagecontactconnection"] = "neu_conf_operationmanagecontactconnection"
$typeToLogical["neu_pharmacyoffer"] = "neu_pharmacyoffer"
$typeToLogical["neu_attachment"] = "neu_attachment"
$typeToLogical["OpportunityClose"] = "opportunityclose"
$typeToLogical["ActivityParty"] = "activityparty"
$typeToLogical["neu_internalfeedbackcategories_item"] = "neu_internalfeedbackcategories_item"
$typeToLogical["neu_deliverypactivityrealization"] = "neu_deliverypactivityrealization"
$typeToLogical["neu_targetimport"] = "neu_targetimport"
$typeToLogical["neu_contractop"] = "neu_contractop"

$allCs = Get-ChildItem -Path $SciezkaRepo -Filter "*.cs" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "\\tests\\|\\obj\\|\\bin\\|\\packages\\|node_modules\\|\\.git\\" }
$seenPhase2 = @{}
foreach ($file in $allCs) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $sourceName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    [regex]::Matches($content, '(\w+)\.Fields\.(\w+)') | ForEach-Object {
        $entType = $_.Groups[1].Value
        $fld = $_.Groups[2].Value
        $entLogical = Get-EntityLogicalName -typeName $entType
        $fieldLogical = To-FieldLogicalName $fld
        $fieldNorm = if ($fieldLogical) { $fieldLogical.Trim().ToLowerInvariant() } else { "" }
        $key = "$entLogical|$fieldNorm|$sourceName"
        if (-not $seenPhase2[$key]) {
            $seenPhase2[$key] = $true
            $results += [pscustomobject]@{ EntityLogicalName = $entLogical; FieldLogicalName = $fieldLogical; PluginAction = $sourceName; SciezkaPliku = $file.FullName }
        }
    }
}

# Faza 2b: W Helpers i Hangfire - dostep przez zmienna.pole (tenderProduct.neu_overheadpercent itd.)
$varToEntity = @{
    "tenderProduct" = "neu_tenderproduct"
    "mappedProduct" = "neu_mappedproduct"
    "postmappedProduct" = "neu_mappedproduct"
    "tenderBundle" = "neu_tenderbundle"
    "postTenderProduct" = "neu_tenderproduct"
}
$helpersOrHangfire = $allCs | Where-Object {
    $_.FullName -match "\\Neuca\.Crm\.Magellan\.Base\\Helpers\\" -or
    $_.FullName -match "\\Neuca\.Crm\.Magellan\.Hangfire\.Web\\"
}
foreach ($file in $helpersOrHangfire) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $sourceName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    [regex]::Matches($content, '\b(tenderProduct|mappedProduct|postmappedProduct|tenderBundle|postTenderProduct)\s*\.\s*(neu_\w+)\b') | ForEach-Object {
        $varName = $_.Groups[1].Value
        $fld = $_.Groups[2].Value
        if (-not $varToEntity[$varName]) { return }
        $entLogical = $varToEntity[$varName]
        $fieldLogical = To-FieldLogicalName $fld
        $fieldNorm = if ($fieldLogical) { $fieldLogical.Trim().ToLowerInvariant() } else { "" }
        $key = "$entLogical|$fieldNorm|$sourceName"
        if (-not $seenPhase2[$key]) {
            $seenPhase2[$key] = $true
            $results += [pscustomobject]@{ EntityLogicalName = $entLogical; FieldLogicalName = $fieldLogical; PluginAction = $sourceName; SciezkaPliku = $file.FullName }
        }
    }
}

$dirOut = Split-Path $SciezkaWyj -Parent
if (-not (Test-Path $dirOut)) { New-Item -ItemType Directory -Path $dirOut -Force | Out-Null }
$results | Export-Csv -Path $SciezkaWyj -NoTypeInformation -Delimiter ";" -Encoding UTF8
Write-Host "Zapisano indeks: $SciezkaWyj ( $($results.Count) wpisow )." -ForegroundColor Green
