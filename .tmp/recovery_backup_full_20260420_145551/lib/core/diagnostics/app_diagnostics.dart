import 'dart:io';

import 'package:flutter/services.dart';

/// Android-only diagnostics via MethodChannel "app.diagnostics".
/// Returns null on non-Android or when a method is not available.
class AppDiagnostics {
  static const MethodChannel _channel = MethodChannel('app.diagnostics');

  /// getPackageName: applicationId at runtime.
  static Future<String?> getPackageName() async {
    if (!Platform.isAndroid) return null;
    try {
      final String? result =
          await _channel.invokeMethod<String>('getPackageName');
      return result;
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// getSigningCertSha1: SHA-1 of the signing cert used at runtime.
  static Future<String?> getSigningCertSha1() async {
    if (!Platform.isAndroid) return null;
    try {
      final String? result =
          await _channel.invokeMethod<String>('getSigningCertSha1');
      return result;
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// getMetaDataValue: reads AndroidManifest meta-data for [key].
  /// For API keys, mask in native code (e.g. first 4 + last 4 chars only).
  static Future<String?> getMetaDataValue(String key) async {
    if (!Platform.isAndroid) return null;
    try {
      final String? result = await _channel.invokeMethod<String>(
          'getMetaDataValue', <String, dynamic>{'key': key});
      return result;
    } on PlatformException catch (_) {
      return null;
    }
  }
}
