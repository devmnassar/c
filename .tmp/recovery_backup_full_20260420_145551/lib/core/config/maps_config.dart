import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Central config for Google Maps API keys.
///
/// Key resolution order (first non-empty wins):
///   1. `--dart-define=MAPS_API_KEY=...` (compile-time, from CLI or Gradle injection)
///   2. Native platform config via method channel (AndroidManifest / Info.plist)
///   3. Empty string -> Directions API calls are skipped, straight-line fallback
///
/// The Gradle build (android/app/build.gradle.kts) auto-injects the debug key
/// from local.properties into dart-defines. For release builds the method channel
/// fallback reads the runtime native key (Android or iOS).
///
/// SECURITY: Restrict keys in Google Cloud Console:
/// - Android: Application restrictions -> Android apps
///   - Package: sa.gaseelexpress.courier.test
///   - Add SHA-1 from debug keystore (./gradlew signingReport) and release keystore
/// - iOS: Application restrictions -> iOS apps
///   - Bundle ID: sa.gaseelexpress.courier.test
/// - API restrictions: Enable "Directions API" + "Maps SDK for Android/iOS"
class MapsConfig {
  MapsConfig._();

  // Compile-time key (from --dart-define or Gradle injection).
  static const String _dartDefineKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '',
  );

  // Runtime state.
  static String? _cachedKey;
  static String _keySource = 'unknown';

  static const _channel = MethodChannel('app.maps_config');

  /// Human-readable source of the currently active key.
  /// One of: `dart-define`, `native-config`, `none`.
  static String get keySource => _keySource;

  /// Whether a usable key has been resolved.
  static bool get keyLoaded => (_cachedKey ?? _dartDefineKey).isNotEmpty;

  /// The compile-time key only (for callers that cannot await).
  /// Prefer [getEffectiveApiKey] which also tries the native fallback.
  static String get directionsApiKey {
    if (_cachedKey != null && _cachedKey!.isNotEmpty) return _cachedKey!;
    return _dartDefineKey;
  }

  /// Resolves the API key asynchronously.
  ///
  /// 1. `--dart-define` / Gradle-injected key (compile-time)
  /// 2. Native platform config via method channel (runtime)
  /// 3. Empty string (no key available)
  ///
  /// Result is cached; safe to call repeatedly (returns instantly after first).
  static Future<String> getEffectiveApiKey() async {
    if (_cachedKey != null) return _cachedKey!;

    if (_dartDefineKey.isNotEmpty) {
      _cachedKey = _dartDefineKey;
      _keySource = 'dart-define';
      _logKeyStatus();
      return _cachedKey!;
    }

    try {
      final nativeKey = await _channel.invokeMethod<String>('getApiKey');
      if (nativeKey != null && nativeKey.isNotEmpty) {
        _cachedKey = nativeKey;
        _keySource = 'native-config';
        _logKeyStatus();
        return _cachedKey!;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MapsConfig] method channel fallback failed: $e');
      }
    }

    _cachedKey = '';
    _keySource = 'none';
    _logKeyStatus();
    return '';
  }

  /// Logs key resolution result (never prints the full key).
  static void _logKeyStatus() {
    if (!kDebugMode) return;
    final loaded = (_cachedKey ?? '').isNotEmpty;
    final masked = loaded
        ? '${_cachedKey!.substring(0, 4)}****${_cachedKey!.substring(_cachedKey!.length - 4)}'
        : '(empty)';
    debugPrint(
      '[MapsConfig] keySource=$_keySource keyLoaded=$loaded keyPreview=$masked',
    );
  }
}
