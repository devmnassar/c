import 'package:flutter/material.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_controller.dart';
import 'core/locale/locale_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  static final GlobalKey<_AppState> appKey = GlobalKey<_AppState>();
  static LocaleController? get localeController =>
      appKey.currentState?._localeController;
  static ThemeController? get themeController =>
      appKey.currentState?._themeController;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final LocaleController _localeController = LocaleController();
  final ThemeController _themeController = ThemeController();

  @override
  void dispose() {
    _localeController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_localeController, _themeController]),
      builder: (context, _) {
        // Wait for locale to load before building MaterialApp
        if (!_localeController.isLoaded) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp.router(
          title: 'Gaseel Courier',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeController.themeMode,
          locale: _localeController.locale, // null = use device locale
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (locale, supportedLocales) {
            // If locale override is set, use it
            if (_localeController.locale != null) {
              return _localeController.locale;
            }
            // Otherwise, use device locale if supported, else fallback to first supported locale
            if (locale != null) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }
            return supportedLocales.first;
          },
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
