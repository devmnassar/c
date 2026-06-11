import 'package:flutter/material.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;

  ThemeController() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final isDark = await SharedPrefHelper.getNullableBool(_themeModeKey);

    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system; // or System
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      await SharedPrefHelper.removeData(_themeModeKey);
    } else {
      await SharedPrefHelper.setData(_themeModeKey, mode == ThemeMode.dark);
    }

    _themeMode = mode;
    notifyListeners();
  }
}
