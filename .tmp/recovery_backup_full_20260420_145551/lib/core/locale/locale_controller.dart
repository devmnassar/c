import 'package:flutter/material.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';
import 'package:get/get.dart';

class LocaleController extends ChangeNotifier {
  static const String _localeCodeKey = 'app_locale';

  Locale? _locale;
  bool _isLoaded = false;

  Locale? get locale => _locale;
  bool get isLoaded => _isLoaded;

  LocaleController() {
    _loadLocale();
  }

  Future<void> loadSavedLocale() async {
    await _loadLocale();
  }

  Future<void> _loadLocale() async {
    final localeCode = await SharedPrefHelper.getNullableString(_localeCodeKey);

    if (localeCode != null && localeCode.isNotEmpty) {
      _locale = Locale(localeCode);
    } else {
      _locale = null; // Use device locale
    }

    try {
      Get.updateLocale(_locale ?? Get.deviceLocale ?? const Locale('en'));
    } catch (_) {}

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    if (_locale?.languageCode == locale?.languageCode) {
      return;
    }

    if (locale == null) {
      // Clear saved preference to use device locale
      await SharedPrefHelper.removeData(_localeCodeKey);
      _locale = null;
      try {
        Get.updateLocale(Get.deviceLocale ?? const Locale('en'));
      } catch (_) {}
      notifyListeners();
    } else {
      // Save locale preference
      await SharedPrefHelper.setData(_localeCodeKey, locale.languageCode);
      _locale = locale;
      try {
        Get.updateLocale(locale);
      } catch (_) {}
      // Update Flutter UI immediately.
      notifyListeners();
    }
  }

  Future<void> clearLocalePreference() async {
    await setLocale(null);
  }

  Future<void> setSystemDefault() async {
    await setLocale(null);
  }

  Future<void> setArabic() async {
    await setLocale(const Locale('ar'));
  }

  Future<void> setEnglish() async {
    await setLocale(const Locale('en'));
  }
}
