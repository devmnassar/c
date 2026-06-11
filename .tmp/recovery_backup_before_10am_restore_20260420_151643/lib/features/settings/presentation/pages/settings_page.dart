import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../app.dart';
import '../../../../core/locale/locale_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../widgets/settings_preference_tile.dart';
import '../widgets/settings_selection_dialog.dart';

class SettingsPage extends StatefulWidget {
  static const String id = '/settings';
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Returns the shared locale controller instance used by the app.
  LocaleController? get _localeController => App.localeController;

  /// Returns the shared theme controller instance used by the app.
  ThemeController? get _themeController => App.themeController;

  /// Applies the selected locale, or resets to system default when null.
  void _changeLanguage(Locale? locale) {
    if (locale == null) {
      _localeController?.setSystemDefault();
    } else {
      _localeController?.setLocale(locale);
    }
  }

  /// Opens language selection dialog and updates the locale based on choice.
  void _showLanguageDialog() {
    if (_localeController == null) return;

    final currentLocale = _localeController!.locale;
    final dialogL10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => SettingsSelectionDialog<String?>(
        title: dialogL10n?.selectLanguage ?? 'Select Language',
        selectedValue: currentLocale?.languageCode,
        options: _buildLanguageOptions(dialogL10n),
        onSelected: (value) {
          if (value == null) {
            _changeLanguage(null);
            return;
          }
          _changeLanguage(Locale(value));
        },
      ),
    );
  }

  /// Builds language options for the reusable settings selection dialog.
  List<SettingsSelectionOption<String?>> _buildLanguageOptions(
    AppLocalizations? lang,
  ) {
    return [
      SettingsSelectionOption<String?>(
        value: null,
        title: lang?.systemDefault ?? 'System default',
        icon: Icons.language,
      ),
      SettingsSelectionOption<String?>(
        value: 'ar',
        title: lang?.arabic ?? 'Arabic',
        icon: Icons.language,
      ),
      SettingsSelectionOption<String?>(
        value: 'en',
        title: lang?.english ?? 'English',
        icon: Icons.language,
      ),
    ];
  }

  /// Returns the current language label shown in the main settings tile.
  String _getCurrentLanguageDisplay(AppLocalizations? l10n) {
    if (_localeController == null) {
      return l10n?.splash ?? 'Loading...';
    }

    final locale = _localeController!.locale;
    if (locale == null) {
      return l10n?.systemDefault ?? 'System default';
    } else if (locale.languageCode == 'ar') {
      return l10n?.arabic ?? 'Arabic';
    } else {
      return l10n?.english ?? 'English';
    }
  }

  /// Returns the current theme label shown in the main settings tile.
  String _getCurrentThemeDisplay(AppLocalizations? l10n) {
    if (_themeController == null) {
      return l10n?.splash ?? 'Loading...';
    }

    final mode = _themeController!.themeMode;
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  /// Builds theme options for the reusable settings selection dialog.
  List<SettingsSelectionOption<ThemeMode>> _buildThemeOptions() {
    return const [
      SettingsSelectionOption<ThemeMode>(
        value: ThemeMode.system,
        title: 'System default',
        icon: Icons.brightness_auto,
      ),
      SettingsSelectionOption<ThemeMode>(
        value: ThemeMode.light,
        title: 'Light',
        icon: Icons.light_mode,
      ),
      SettingsSelectionOption<ThemeMode>(
        value: ThemeMode.dark,
        title: 'Dark',
        icon: Icons.dark_mode,
      ),
    ];
  }

  /// Opens theme selection dialog and applies the selected theme mode.
  void _showThemeDialog() {
    if (_themeController == null) return;

    final currentMode = _themeController!.themeMode;

    showDialog(
      context: context,
      builder: (context) => SettingsSelectionDialog<ThemeMode>(
        title: 'Select Theme',
        selectedValue: currentMode,
        options: _buildThemeOptions(),
        onSelected: (mode) => _themeController?.setThemeMode(mode),
      ),
    );
  }

  /// Builds the settings page layout with language and theme preferences.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.settings ?? 'Settings')),
      body: ListView(
        children: [
          SettingsPreferenceTile(
            listenable: _localeController ?? ValueNotifier(null),
            leading: const Icon(Icons.language),
            title: Text(l10n?.language ?? 'Language'),
            subtitle: _getCurrentLanguageDisplay(l10n),
            onTap: _showLanguageDialog,
          ),
          const Divider(),
          SettingsPreferenceTile(
            listenable: _themeController ?? ValueNotifier(null),
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            subtitle: _getCurrentThemeDisplay(l10n),
            onTap: _showThemeDialog,
          ),
        ],
      ),
    );
  }
}
