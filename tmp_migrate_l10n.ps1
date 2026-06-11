$enJson = Get-Content -Raw -LiteralPath "lib/l10n/app_en.arb" -Encoding UTF8 | ConvertFrom-Json
$keyToEn = @{}
foreach($p in $enJson.PSObject.Properties){
  if($p.Name.StartsWith('@')){ continue }
  if($p.Value -is [string]){ $keyToEn[$p.Name] = [string]$p.Value }
}
$files = Get-ChildItem -Path lib -Recurse -File -Filter *.dart | Where-Object {
  $_.FullName -notmatch "\\lib\\l10n\\" -and $_.FullName -notmatch "\\lib\\core\\locale\\core_translations_data\.dart$"
}
$changed = 0
foreach($f in $files){
  $content = Get-Content -Raw -LiteralPath $f.FullName
  $orig = $content

  foreach($k in $keyToEn.Keys){
    $en = $keyToEn[$k].Replace("'","\\'")
    $rep = "AppI18n.t('$en', context: context)"
    $content = [regex]::Replace($content, "\\bl10n\\." + [regex]::Escape($k) + "\\b(?!\\s*\\()", $rep)
    $content = [regex]::Replace($content, "\\bl10n\\?\\." + [regex]::Escape($k) + "\\b(?!\\s*\\()", $rep)
    $content = [regex]::Replace($content, "AppLocalizations\\.of\\(context\\)!\\." + [regex]::Escape($k) + "\\b(?!\\s*\\()", $rep)
    $content = [regex]::Replace($content, "AppLocalizations\\.of\\(context\\)\\?\\." + [regex]::Escape($k) + "\\b(?!\\s*\\()", $rep)
  }

  if($content -ne $orig){
    if($content -notmatch "package:gaseel_courier/core/locale/app_i18n\.dart"){
      if($content -match "(?m)^import "){
        $content = [regex]::Replace($content, "(?m)^(import\s+'[^']+';\r?\n)", "`$1import 'package:gaseel_courier/core/locale/app_i18n.dart';`r`n", 1)
      }
    }
    Set-Content -LiteralPath $f.FullName -Value $content -NoNewline
    $changed++
    Write-Output "changed: $($f.FullName)"
  }
}
Write-Output "TOTAL_CHANGED=$changed"
