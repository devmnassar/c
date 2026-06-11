import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Future replacement for duplicated `_resolveL10n` helpers in mega screens.
///
/// Phase 1: additive only — not imported by production code yet.
///
/// TODO: After adoption, remove private `_resolveL10n` functions from:
/// - delivery_to_customer_page.dart
/// - courier_map_status_screen.dart
/// - incoming_order_page.dart
/// - active_trip_page.dart
/// - (and other files with the same pattern)
extension L10nContextExtension on BuildContext {
  /// Returns [AppLocalizations] from the widget tree when available.
  ///
  /// Falls back to [lookupAppLocalizations] for a supported locale, then
  /// English — matching the behavior of existing `_resolveL10n` helpers.
  AppLocalizations get l10nOrEn {
    final l10n = AppLocalizations.of(this);
    if (l10n != null) {
      return l10n;
    }

    final locale = Localizations.maybeLocaleOf(this);
    if (locale != null) {
      final supported = AppLocalizations.supportedLocales.any(
        (supportedLocale) =>
            supportedLocale.languageCode == locale.languageCode,
      );
      if (supported) {
        return lookupAppLocalizations(locale);
      }
    }

    return lookupAppLocalizations(const Locale('en'));
  }
}
