import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RequestStatusInterceptor extends Interceptor {
  static const String _startTimeKey = 'request_start_time_ms';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
    _log(
      stage: 'LOADING',
      method: options.method,
      path: _normalizePath(options.path),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      stage: 'SUCCESS',
      method: response.requestOptions.method,
      path: _normalizePath(response.requestOptions.path),
      statusCode: response.statusCode,
      durationMs: _durationInMs(response.requestOptions),
    );
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _log(
      stage: 'ERROR',
      method: err.requestOptions.method,
      path: _normalizePath(err.requestOptions.path),
      statusCode: err.response?.statusCode,
      durationMs: _durationInMs(err.requestOptions),
      errorMessage: err.message,
    );
    handler.next(err);
  }

  int? _durationInMs(RequestOptions options) {
    final startedAt = options.extra[_startTimeKey];
    if (startedAt is int) {
      return DateTime.now().millisecondsSinceEpoch - startedAt;
    }
    return null;
  }

  String _normalizePath(String path) {
    try {
      final uri = Uri.parse(path);
      if (uri.path.isNotEmpty) {
        return uri.path;
      }
    } catch (_) {}
    return path;
  }

  void _log({
    required String stage,
    required String method,
    required String path,
    int? statusCode,
    int? durationMs,
    String? errorMessage,
  }) {
    if (!kDebugMode) return;

    final details = <String>[
      '[REQUEST][$stage]',
      method.toUpperCase(),
      path,
      if (statusCode != null) 'status=$statusCode',
      if (durationMs != null) 'time=${durationMs}ms',
      if (errorMessage != null && errorMessage.trim().isNotEmpty)
        'message=${errorMessage.trim()}',
    ].join(' ');

    debugPrint(details);
  }
}
