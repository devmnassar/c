import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../app.dart';
import '../../../../core/locale/locale_controller.dart';
import '../../../../core/theme/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  static const String id = '/home/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  LocaleController? get _localeController => App.localeController;
  ThemeController? get _themeController => App.themeController;

  void _changeLanguage(Locale? locale) {
    if (locale == null) {
      _localeController?.setSystemDefault();
    } else {
      _localeController?.setLocale(locale);
    }
  }

  void _showLanguageDialog() {
    if (_localeController == null) return;

    final currentLocale = _localeController!.locale;
    final dialogL10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogL10n?.selectLanguage ?? 'Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(dialogL10n?.systemDefault ?? 'System default'),
              trailing: currentLocale == null
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeLanguage(null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(dialogL10n?.arabic ?? 'Arabic'),
              trailing: currentLocale?.languageCode == 'ar'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeLanguage(const Locale('ar'));
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(dialogL10n?.english ?? 'English'),
              trailing: currentLocale?.languageCode == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeLanguage(const Locale('en'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    await _themeController?.setThemeMode(mode);
  }

  void _showThemeDialog() {
    final controller = _themeController;
    if (controller == null) return;

    final currentMode = controller.themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Theme'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: Text('systemDefault'.tr ?? 'System default'),
              trailing: currentMode == ThemeMode.system
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeThemeMode(ThemeMode.system);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: Text('Light'.tr),
              trailing: currentMode == ThemeMode.light
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeThemeMode(ThemeMode.light);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text('Dark'.tr),
              trailing: currentMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.of(context).pop();
                _changeThemeMode(ThemeMode.dark);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentLanguageDisplay(AppLocalizations? l10n) {
    if (_localeController == null) {
      return 'splash'.tr ?? 'Loading...';
    }

    final locale = _localeController!.locale;
    if (locale == null) {
      return 'systemDefault'.tr ?? 'System default';
    } else if (locale.languageCode == 'ar') {
      return 'arabic'.tr ?? 'Arabic';
    } else {
      return 'english'.tr ?? 'English';
    }
  }

  String _getCurrentThemeDisplay() {
    final mode = _themeController?.themeMode ?? ThemeMode.system;
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark'.tr;
      case ThemeMode.light:
        return 'Light'.tr;
      case ThemeMode.system:
        return 'systemDefault'.tr ?? 'System default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr ?? 'Settings'),
      ),
      body: ListView(
        children: [
          ListenableBuilder(
            listenable: _localeController ?? ValueNotifier(null),
            builder: (context, _) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text('language'.tr ?? 'Language'),
                subtitle: Text(_getCurrentLanguageDisplay(l10n)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showLanguageDialog,
              );
            },
          ),
          ListenableBuilder(
            listenable: _themeController ?? ValueNotifier(null),
            builder: (context, _) {
              return ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text('Theme'.tr),
                subtitle: Text(_getCurrentThemeDisplay()),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showThemeDialog,
              );
            },
          ),
        ],
      ),
    );
  }
}
