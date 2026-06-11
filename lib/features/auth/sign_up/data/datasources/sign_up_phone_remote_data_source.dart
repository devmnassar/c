import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/networking/api_constants.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/register_auth_result_model.dart';
import '../models/send_register_otp_result_model.dart';
import '../models/verify_register_otp_result_model.dart';

class SignUpPhoneRemoteDataSource {
  const SignUpPhoneRemoteDataSource(this._dio);

  final Dio _dio;

  String _sanitizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  Future<SendRegisterOtpResultModel> sendRegisterOtp({
    required String phoneNumber,
  }) async {
    final sanitizedPhoneNumber = _sanitizePhoneNumber(phoneNumber);
    try {
      _logRequest(
        endpoint: '/api/otp/register/send',
        body: {'phoneNumber': sanitizedPhoneNumber},
      );
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.sendRegisterOtp,
        data: {'phoneNumber': sanitizedPhoneNumber},
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/otp/register/send', data: data);
      _logOtpIfAvailable(data);
      return SendRegisterOtpResultModel.fromJson(data);
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/otp/register/send', error: error);
      throw _mapDioException(error);
    }
  }

  Future<VerifyRegisterOtpResultModel> verifyRegisterOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final sanitizedPhoneNumber = _sanitizePhoneNumber(phoneNumber);
    try {
      _logRequest(
        endpoint: '/api/otp/register/verify',
        body: {
          'phoneNumber': sanitizedPhoneNumber,
          'code': code,
        },
      );
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.verifyRegisterOtp,
        data: {
          'phoneNumber': sanitizedPhoneNumber,
          'code': code,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/otp/register/verify', data: data);
      return VerifyRegisterOtpResultModel.fromJson(data);
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/otp/register/verify', error: error);
      throw _mapDioException(error);
    }
  }

  Future<RegisterAuthResultModel> registerWithPhone({
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    final sanitizedPhoneNumber = _sanitizePhoneNumber(phoneNumber);
    try {
      _logRequest(
        endpoint: '/api/auth/register',
        body: {
          'phoneNumber': sanitizedPhoneNumber,
          'password': '******',
          'confirmPassword': '******',
        },
      );
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: {
          'phoneNumber': sanitizedPhoneNumber,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/auth/register', data: data);
      return RegisterAuthResultModel.fromJson(data);
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/auth/register', error: error);
      throw _mapDioException(error);
    }
  }

  void _logRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) {
    if (!kDebugMode) return;
    debugPrint('[Auth API Request] $endpoint');
    debugPrint('[Auth API Body] ${jsonEncode(body)}');
  }

  void _logResponse({
    required String endpoint,
    required Map<String, dynamic> data,
  }) {
    if (!kDebugMode) return;
    debugPrint('[Auth API Response] $endpoint');
    debugPrint('[Auth API Data] ${jsonEncode(data)}');
  }

  void _logOtpIfAvailable(Map<String, dynamic> data) {
    if (!kDebugMode) return;
    if (data.containsKey('otpCode')) {
      debugPrint('[Auth OTP] ${data['otpCode']}');
    }
  }

  void _logDioError({
    required String endpoint,
    required DioException error,
  }) {
    if (!kDebugMode) return;
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    debugPrint('[Auth API Error] $endpoint');
    debugPrint('[Auth API Error Status] $statusCode');
    if (responseData != null) {
      debugPrint('[Auth API Error Data] ${jsonEncode(responseData)}');
    } else {
      debugPrint('[Auth API Error Message] ${error.message}');
    }
  }

  ApiException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    final extractedMessage = _extractMessageFromResponseData(data);
    if (extractedMessage != null && extractedMessage.isNotEmpty) {
      return ApiException(message: extractedMessage, statusCode: statusCode);
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

  String? _extractMessageFromResponseData(dynamic data) {
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
