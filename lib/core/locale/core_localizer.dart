import 'package:flutter/widgets.dart';
import 'package:gaseel_courier/app.dart';
import 'package:gaseel_courier/core/locale/app_translations.dart';
import 'package:get/get.dart';

class CoreLocalizer {
  const CoreLocalizer._();

  static final AppTranslations _translations = AppTranslations();

  static Locale _resolvedLocale([BuildContext? context]) {
    final ctx = context ?? App.appKey.currentContext;
    final fromContext = ctx != null ? Localizations.maybeLocaleOf(ctx) : null;
    final fromGet = Get.locale;
    final fromController = App.localeController?.locale;
    final fromDevice = Get.deviceLocale;

    return fromContext ??
        fromGet ??
        fromController ??
        fromDevice ??
        const Locale('en');
  }

  static bool isArabic([BuildContext? context]) {
    final locale = _resolvedLocale(context);
    return locale.languageCode.toLowerCase() == 'ar';
  }

  static String t(
    String key, {
    BuildContext? context,
    Map<String, String>? params,
  }) {
    final localeCode = _resolvedLocale(context).languageCode.toLowerCase();
    final langMap = _translations.keys[localeCode] ?? _translations.keys['en']!;
    final value = langMap[key] ?? key;

    if (params == null || params.isEmpty) {
      return value;
    }

    var resolved = value;
    params.forEach((name, rawValue) {
      resolved = resolved.replaceAll('{$name}', rawValue);
      resolved = resolved.replaceAll('\${$name}', rawValue);
    });
    return resolved;
  }
}

extension CoreLocalizerBuildContextX on BuildContext {
  String t(
    String key, {
    Map<String, String>? params,
  }) {
    return CoreLocalizer.t(key, context: this, params: params);
  }
}
