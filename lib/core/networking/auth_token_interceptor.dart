import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/auth/auth_service.dart';
import 'package:gaseel_courier/core/helpers/constants.dart';
import 'package:gaseel_courier/core/helpers/shared_pref_helper.dart';

import 'api_constants.dart';

class AuthTokenInterceptor extends QueuedInterceptor {
  AuthTokenInterceptor(this._dio);

  static const String _retryAttemptedKey = 'retry_attempted_after_refresh';

  final Dio _dio;
  final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  Completer<bool>? _refreshCompleter;
  bool _isForceLogoutInProgress = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicPath(options.path)) {
      return handler.next(options);
    }

    final accessToken = await _readAccessToken();
    if (accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
      _log(
        '[AUTH INTERCEPTOR] Authorization attached for ${_pathOnly(options.path)} '
        '(tokenLength=${accessToken.length})',
      );
    } else {
      _log(
        '[AUTH INTERCEPTOR] No access token found for ${_pathOnly(options.path)}',
      );
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final statusCode = err.response?.statusCode ?? 0;
    final isUnauthorized = statusCode == 401;
    final alreadyRetried = request.extra[_retryAttemptedKey] == true;

    if (!isUnauthorized ||
        alreadyRetried ||
        _isPublicPath(request.path) ||
        _isRefreshPath(request.path)) {
      return handler.next(err);
    }

    _log('================ TOKEN REFRESH FLOW START ================');
    _log('[AUTH INTERCEPTOR] 401 detected for: ${request.path}');

    final refreshed = await _refreshTokenSingleFlight();
    _log('[AUTH INTERCEPTOR] Refresh result: $refreshed');
    if (!refreshed) {
      await _forceLogout();
      _log('[AUTH INTERCEPTOR] Refresh failed -> auto logout');
      _log('================ TOKEN REFRESH FLOW END ==================');
      return handler.next(err);
    }

    final newAccessToken = await _readAccessToken();
    if (newAccessToken.isEmpty) {
      await _forceLogout();
      _log('[AUTH INTERCEPTOR] Missing access token after refresh -> logout');
      _log('================ TOKEN REFRESH FLOW END ==================');
      return handler.next(err);
    }

    try {
      final retryResponse = await _retryWithNewToken(
        request: request,
        accessToken: newAccessToken,
      );
      _log('[AUTH INTERCEPTOR] Request retried successfully: ${request.path}');
      _log('================ TOKEN REFRESH FLOW END ==================');
      return handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      _log('[AUTH INTERCEPTOR] Retry failed: ${retryError.message}');
      if ((retryError.response?.statusCode ?? 0) == 401) {
        await _forceLogout();
      }
      _log('================ TOKEN REFRESH FLOW END ==================');
      return handler.next(retryError);
    } catch (retryError) {
      _log('[AUTH INTERCEPTOR] Retry unexpected error: $retryError');
      await _forceLogout();
      _log('================ TOKEN REFRESH FLOW END ==================');
      return handler.next(err);
    }
  }

  Future<bool> _refreshTokenSingleFlight() async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      _log('[AUTH INTERCEPTOR] Awaiting running refresh request...');
      return inFlight.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final result = await _performRefresh();
      completer.complete(result);
      return result;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _performRefresh() async {
    final accessToken = await _readAccessToken();
    final refreshToken = await _readRefreshToken();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      _log('[AUTH INTERCEPTOR] No stored tokens -> cannot refresh');
      return false;
    }

    _log('[AUTH INTERCEPTOR] Calling /api/auth/refresh-token');

    try {
      final response = await _refreshDio.post<dynamic>(
        ApiConstants.refreshToken,
        data: {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        },
      );

      if (response.statusCode != 200 ||
          response.data is! Map<String, dynamic>) {
        _log(
          '[AUTH INTERCEPTOR] Refresh invalid response: ${response.statusCode}',
        );
        return false;
      }

      final data = response.data! as Map<String, dynamic>;
      final newAccessToken = _readString(data, 'accessToken', 'AccessToken');
      final newRefreshToken = _readString(data, 'refreshToken', 'RefreshToken');

      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        _log('[AUTH INTERCEPTOR] Refresh response missing token values');
        return false;
      }

      await SharedPrefHelper.setSecuredString(
        SharedPrefKeys.userToken,
        newAccessToken,
      );
      await SharedPrefHelper.setSecuredString(
        SharedPrefKeys.refreshToken,
        newRefreshToken,
      );

      await _persistAuthMeta(data);
      _log('[AUTH INTERCEPTOR] Refresh succeeded and tokens updated');
      return true;
    } on DioException catch (error) {
      _log(
        '[AUTH INTERCEPTOR] Refresh failed: status=${error.response?.statusCode} data=${error.response?.data}',
      );
      return false;
    } catch (error) {
      _log('[AUTH INTERCEPTOR] Refresh unexpected error: $error');
      return false;
    }
  }

  Future<Response<dynamic>> _retryWithNewToken({
    required RequestOptions request,
    required String accessToken,
  }) {
    final headers = Map<String, dynamic>.from(request.headers);
    headers['Authorization'] = 'Bearer $accessToken';

    final extra = Map<String, dynamic>.from(request.extra);
    extra[_retryAttemptedKey] = true;

    return _dio.request<dynamic>(
      request.path,
      data: request.data,
      queryParameters: request.queryParameters,
      cancelToken: request.cancelToken,
      onSendProgress: request.onSendProgress,
      onReceiveProgress: request.onReceiveProgress,
      options: Options(
        method: request.method,
        headers: headers,
        extra: extra,
        responseType: request.responseType,
        contentType: request.contentType,
        sendTimeout: request.sendTimeout,
        receiveTimeout: request.receiveTimeout,
        validateStatus: request.validateStatus,
        receiveDataWhenStatusError: request.receiveDataWhenStatusError,
        followRedirects: request.followRedirects,
        maxRedirects: request.maxRedirects,
        persistentConnection: request.persistentConnection,
        listFormat: request.listFormat,
      ),
    );
  }

  Future<void> _persistAuthMeta(Map<String, dynamic> data) async {
    final userId = _readString(data, 'userId', 'UserId');
    final userName = _readString(data, 'userName', 'UserName');
    final phoneNumber = _readString(data, 'phoneNumber', 'PhoneNumber');
    final expiresInMinutes =
        _readInt(data, 'expiresInMinutes', 'ExpiresInMinutes');
    final isActive = _readBool(data, 'isActive', 'IsActive');
    final isRejected = _readBool(data, 'isRejected', 'IsRejected');
    final isPhoneVerified = _readBool(
      data,
      'isPhoneVerified',
      'IsPhoneVerified',
    );

    await SharedPrefHelper.setData(SharedPrefKeys.authUserId, userId);
    await SharedPrefHelper.setData(SharedPrefKeys.authUserName, userName);
    await SharedPrefHelper.setData(SharedPrefKeys.authPhoneNumber, phoneNumber);
    await SharedPrefHelper.setData(
      SharedPrefKeys.authExpiresInMinutes,
      expiresInMinutes,
    );
    await SharedPrefHelper.setData(SharedPrefKeys.authIsActive, isActive);
    await SharedPrefHelper.setData(SharedPrefKeys.authIsRejected, isRejected);
    await SharedPrefHelper.setData(
      SharedPrefKeys.authIsPhoneVerified,
      isPhoneVerified,
    );

    await _persistCourierWorkTypeHints(data);
  }

  Future<void> _persistCourierWorkTypeHints(Map<String, dynamic> data) async {
    const stringKeys = <String>[
      'courierWorkType',
      'courierType',
      'driverType',
      'employmentType',
      'userType',
    ];
    for (final key in stringKeys) {
      final value = _readLooseString(data, key);
      if (value != null && value.isNotEmpty) {
        await SharedPrefHelper.setData(key, value);
      }
    }

    const boolKeys = <String>[
      'isFreelancer',
      'isCompanyCourier',
      'isFullTimeCourier',
      'isFullTime',
    ];
    for (final key in boolKeys) {
      final value = _readLooseBool(data, key);
      if (value != null) {
        await SharedPrefHelper.setData(key, value);
      }
    }
  }

  Future<void> _forceLogout() async {
    if (_isForceLogoutInProgress) {
      return;
    }
    _isForceLogoutInProgress = true;
    try {
      _log('[AUTH INTERCEPTOR] Triggering force logout...');
      await AuthService.logout();
      _log('[AUTH INTERCEPTOR] Force logout finished.');
    } finally {
      _isForceLogoutInProgress = false;
    }
  }

  Future<String> _readAccessToken() async {
    return SharedPrefHelper.getSecuredString(SharedPrefKeys.userToken);
  }

  Future<String> _readRefreshToken() async {
    return SharedPrefHelper.getSecuredString(SharedPrefKeys.refreshToken);
  }

  bool _isPublicPath(String path) {
    final normalized = _pathOnly(path);
    const publicPaths = <String>{
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth/refresh-token',
      '/api/auth/reset-password',
      '/api/otp/register/send',
      '/api/otp/register/verify',
      '/api/otp/reset-password/send',
      '/api/otp/reset-password/verify',
    };
    return publicPaths.contains(normalized);
  }

  bool _isRefreshPath(String path) {
    return _pathOnly(path) == '/api/auth/refresh-token';
  }

  String? _readLooseString(Map<String, dynamic> data, String key) {
    final variants = <String>{key, _capitalizeFirst(key)};
    for (final variant in variants) {
      final value = data[variant];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  bool? _readLooseBool(Map<String, dynamic> data, String key) {
    final variants = <String>{key, _capitalizeFirst(key)};
    for (final variant in variants) {
      final value = data[variant];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }
    }
    return null;
  }

  String _capitalizeFirst(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  String _pathOnly(String urlOrPath) {
    try {
      final uri = Uri.parse(urlOrPath);
      return uri.path.isNotEmpty ? uri.path : urlOrPath;
    } catch (_) {
      return urlOrPath;
    }
  }

  String _readString(Map<String, dynamic> data, String key1, String key2) {
    final dynamic raw = data[key1] ?? data[key2];
    return (raw as String?)?.trim() ?? '';
  }

  int _readInt(Map<String, dynamic> data, String key1, String key2) {
    final dynamic raw = data[key1] ?? data[key2];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  bool _readBool(Map<String, dynamic> data, String key1, String key2) {
    final dynamic raw = data[key1] ?? data[key2];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final value = raw.toLowerCase().trim();
      return value == 'true' || value == '1';
    }
    return false;
  }

  void _log(String message) {
    debugPrint(message);
  }
}
