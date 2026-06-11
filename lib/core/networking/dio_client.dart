import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'auth_token_interceptor.dart';
import 'request_status_interceptor.dart';

Dio createDioClient() {
  final dio = Dio(
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

  dio.interceptors.add(RequestStatusInterceptor());
  dio.interceptors.add(AuthTokenInterceptor(dio));
  return dio;
}
