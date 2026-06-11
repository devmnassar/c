import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';

class FcmTokenService {
  FcmTokenService._();

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _log('Initializing FCM token lifecycle...');
    await _requestPermission();
    await refreshAndCacheToken(reason: 'app_startup');
    _listenToTokenRefresh();
  }

  static Future<void> refreshAndCacheToken({
    String reason = 'manual_refresh',
  }) async {
    try {
      _log('Refreshing FCM token. reason=$reason');
      final token = (await FirebaseMessaging.instance.getToken())?.trim() ?? '';
      if (token.isEmpty) {
        _log('FCM token is unavailable right now. reason=$reason');
        return;
      }

      await SharedPrefHelper.setData(SharedPrefKeys.firebaseFcmToken, token);
      _log('FCM token cached successfully. reason=$reason');
      _log('FCM token preview: ${_maskToken(token)}');
    } catch (error, stackTrace) {
      _log('Failed to refresh FCM token. reason=$reason error=$error');
      debugPrint('[FCM TOKEN] $stackTrace');
    }
  }

  static Future<String?> getCachedToken() async {
    final token = await SharedPrefHelper.getNullableString(
      SharedPrefKeys.firebaseFcmToken,
    );
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static Future<String?> getCachedOrRefreshToken() async {
    final cachedToken = await getCachedToken();
    if (cachedToken != null) {
      _log('Using cached FCM token.');
      return cachedToken;
    }

    _log('Cached FCM token not found. Refreshing...');
    await refreshAndCacheToken(reason: 'cache_miss');
    return getCachedToken();
  }

  static Future<void> clearCachedToken() async {
    _log('Clearing cached FCM token.');
    await SharedPrefHelper.removeData(SharedPrefKeys.firebaseFcmToken);
  }

  static Future<void> _requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _log('Notification permission status: ${settings.authorizationStatus}');
    } catch (error, stackTrace) {
      _log('Failed to request notification permission: $error');
      debugPrint('[FCM TOKEN] $stackTrace');
    }
  }

  static void _listenToTokenRefresh() {
    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) async {
        final normalizedToken = token.trim();
        if (normalizedToken.isEmpty) {
          _log('Received empty token from onTokenRefresh.');
          return;
        }

        await SharedPrefHelper.setData(
          SharedPrefKeys.firebaseFcmToken,
          normalizedToken,
        );
        _log('FCM token updated from onTokenRefresh.');
        _log('FCM token preview: ${_maskToken(normalizedToken)}');
      },
      onError: (Object error, StackTrace stackTrace) {
        _log('onTokenRefresh stream error: $error');
        debugPrint('[FCM TOKEN] $stackTrace');
      },
    );
  }

  static String _maskToken(String token) {
    if (token.length <= 12) {
      return token;
    }
    return '${token.substring(0, 6)}...${token.substring(token.length - 6)}';
  }

  static void _log(String message) {
    debugPrint('[FCM TOKEN] $message');
  }
}
