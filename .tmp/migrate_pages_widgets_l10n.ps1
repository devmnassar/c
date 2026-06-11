$targets = rg -l 'AppI18n\.tr\(|AppI18n\.t\(' lib --glob '**/pages/*.dart' --glob '**/widgets/*.dart' --glob 'lib/screens/*.dart'

$patternT = 'AppI18n\.t\(\s*''([^'']*)''\s*,\s*context:\s*context\s*\)'
$patternTr = 'AppI18n\.tr\(\s*context:\s*context\s*,\s*en:\s*''([^'']*)''\s*,\s*ar:\s*''[^'']*''\s*,?\s*\)'

foreach ($path in $targets) {
  $c = Get-Content -Raw -Path $path
  $u = $c

  $u = [regex]::Replace($u, $patternT, '''$1''.tr')
  $u = [regex]::Replace($u, $patternTr, '''$1''.tr', [System.Text.RegularExpressions.RegexOptions]::Singleline)

  $u = $u -replace "\r?\nimport 'package:gaseel_courier/core/locale/app_i18n.dart';", ''

  if ($u -match '\.tr\b' -and $u -notmatch "package:get/get_utils/get_utils.dart" -and $u -notmatch "package:get/get.dart") {
    if ($u -match "import 'package:flutter/material.dart';") {
      $u = $u -replace "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';`r`nimport 'package:get/get_utils/get_utils.dart';"
    } elseif ($u -match "import 'package:flutter/widgets.dart';") {
      $u = $u -replace "import 'package:flutter/widgets.dart';", "import 'package:flutter/widgets.dart';`r`nimport 'package:get/get_utils/get_utils.dart';"
    }
  }

  if ($u -ne $c) {
    Set-Content -Path $path -Value $u -NoNewline
  }
}
