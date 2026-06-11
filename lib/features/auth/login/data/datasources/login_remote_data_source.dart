import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/networking/api_constants.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../../domain/entities/login_credentials.dart';
import '../models/auth_user_model.dart';

class LoginRemoteDataSource {
  const LoginRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthUserModel> login(LoginCredentials credentials) async {
    try {
      _logRequest(
        endpoint: '/api/auth/login',
        body: {
          'phoneNumber': credentials.sanitizedPhoneNumber,
          'password': '******',
        },
      );
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {
          'login': credentials.sanitizedPhoneNumber,
          'password': credentials.password,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/auth/login', data: data);
      return AuthUserModel.fromJson(data);
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/auth/login', error: error);
      throw _mapDioException(error);
    }
  }

  void _logRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ LOGIN API REQUEST ================');
    debugPrint('[LOGIN API Request] $endpoint');
    debugPrint('[LOGIN API Body] ${jsonEncode(body)}');
  }

  void _logResponse({
    required String endpoint,
    required Map<String, dynamic> data,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ LOGIN API RESPONSE ================');
    debugPrint('[LOGIN API Response] $endpoint');
    debugPrint('[LOGIN API Data] ${jsonEncode(data)}');
  }

  void _logDioError({
    required String endpoint,
    required DioException error,
  }) {
    if (!kDebugMode) return;
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    debugPrint('================ LOGIN API ERROR ================');
    debugPrint('[LOGIN API Error] $endpoint');
    debugPrint('[LOGIN API Error Status] $statusCode');
    if (responseData != null) {
      debugPrint('[LOGIN API Error Data] ${jsonEncode(responseData)}');
    } else {
      debugPrint('[LOGIN API Error Message] ${error.message}');
    }
  }

  ApiException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = _extractMessage(error.response?.data);
    if (message != null && message.isNotEmpty) {
      return ApiException(message: message, statusCode: statusCode);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message: 'Connection timeout. Please try again.',
        statusCode: statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'No internet connection. Please check your network.',
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: 'Unexpected error occurred. Please try again.',
      statusCode: statusCode,
    );
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic rawMessage = data['message'] ?? data['Message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        return rawMessage.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}
