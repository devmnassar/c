$targets = rg -l 'AppI18n\.tr\(|AppI18n\.t\(' lib/core lib/features --glob '*.dart'
$targets = $targets | Where-Object { $_ -notlike '*lib\core\locale\app_i18n.dart' -and $_ -notlike '*lib\core\locale\legacy_l10n_proxy.dart' -and $_ -notlike '*lib\features\auth\auth_i18n.dart' }

$patternTWithContext = 'AppI18n\.t\(\s*''([^'']*)''\s*,\s*context:\s*context\s*\)'
$patternTNoContext = 'AppI18n\.t\(\s*''([^'']*)''\s*\)'
$patternTr = 'AppI18n\.tr\(\s*context:\s*context\s*,\s*en:\s*''([^'']*)''\s*,\s*ar:\s*''[^'']*''\s*,?\s*\)'

foreach ($path in $targets) {
  $c = Get-Content -Raw -Path $path
  $u = $c

  $u = [regex]::Replace($u, $patternTWithContext, '''$1''.tr')
  $u = [regex]::Replace($u, $patternTNoContext, '''$1''.tr')
  $u = [regex]::Replace($u, $patternTr, '''$1''.tr', [System.Text.RegularExpressions.RegexOptions]::Singleline)

  $u = $u -replace "\r?\nimport 'package:gaseel_courier/core/locale/app_i18n.dart';", ''
  $u = $u -replace "\r?\nimport '../../../auth_i18n.dart';", ''
  $u = $u -replace "\r?\nimport '\.\./\.\./\.\./auth_i18n.dart';", ''

  if ($u -match '\.tr\b' -and $u -notmatch "package:get/get_utils/get_utils.dart" -and $u -notmatch "package:get/get.dart") {
    if ($u -match "import 'package:flutter/material.dart';") {
      $u = $u -replace "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';`r`nimport 'package:get/get_utils/get_utils.dart';"
    } elseif ($u -match "import 'package:flutter/widgets.dart';") {
      $u = $u -replace "import 'package:flutter/widgets.dart';", "import 'package:flutter/widgets.dart';`r`nimport 'package:get/get_utils/get_utils.dart';"
    } else {
      # add after first import line
      $u = [regex]::Replace($u, "(import '.*?';\r?\n)", "`$1import 'package:get/get_utils/get_utils.dart';`r`n", 1)
    }
  }

  if ($u -ne $c) {
    Set-Content -Path $path -Value $u -NoNewline
  }
}
