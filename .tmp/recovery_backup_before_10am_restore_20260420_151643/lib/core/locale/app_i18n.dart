import 'package:flutter/widgets.dart';
import 'package:gaseel_courier/core/locale/core_localizer.dart';

/// Unified lightweight i18n helper for feature-level strings that are not yet
/// moved to ARB keys.
class AppI18n {
  const AppI18n._();

  static bool isArabic([BuildContext? context]) {
    return CoreLocalizer.isArabic(context);
  }

  /// Preferred API: English sentence (or key) is the single source key.
  static String t(
    String key, {
    BuildContext? context,
    Map<String, String>? params,
  }) {
    return CoreLocalizer.t(key, context: context, params: params);
  }

  @Deprecated('Use AppI18n.t(key) with English key only')
  static String tr({
    BuildContext? context,
    required String en,
    required String ar,
  }) {
    return t(en, context: context);
  }
}

extension AppI18nContextX on BuildContext {
  String t(
    String key, {
    Map<String, String>? params,
  }) {
    return AppI18n.t(key, context: this, params: params);
  }

  @Deprecated('Use context.t(key) with English key only')
  String tr({
    required String en,
    required String ar,
  }) {
    return AppI18n.t(en, context: this);
  }
}
