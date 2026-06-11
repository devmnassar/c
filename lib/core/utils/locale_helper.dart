import 'package:flutter/material.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';

class LocaleHelper {
  static const Locale defaultLocale = Locale('ar');

  static Future<Locale> getSavedLocale() async {
    final localeCode =
        (await SharedPrefHelper.getNullableString('locale')) ?? 'ar';
    return Locale(localeCode);
  }

  static Future<void> saveLocale(Locale locale) async {
    await SharedPrefHelper.setData('locale', locale.languageCode);
  }

  static TextDirection getTextDirection(Locale locale) {
    return locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }
}
