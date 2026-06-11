import 'package:flutter/services.dart';

/// Bridge to set native (Android/iOS) app locale so platform views (e.g. Google Map)
/// use the same language as the Flutter app.
class NativeLocaleBridge {
  static const MethodChannel _channel = MethodChannel('app.locale');

  /// Notifies the platform to apply [langCode] (e.g. 'ar', 'en') so that
  /// native UI (including map labels) matches the app-selected locale.
  /// Call this after updating Flutter locale so the map rebuilds with the new language.
  static Future<void> setLocale(String langCode) async {
    try {
      await _channel.invokeMethod<void>('setLocale', {'lang': langCode});
    } on PlatformException catch (e) {
      // Ignore if platform does not implement the channel (e.g. web)
      assert(
        e.code == 'not_implemented' || e.message?.contains('setLocale') == true,
        'NativeLocaleBridge.setLocale: $e',
      );
    }
  }
}
