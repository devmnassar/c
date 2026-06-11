import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/networking/api_constants.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/reset_password_result_model.dart';
import '../models/send_reset_otp_result_model.dart';
import '../models/verify_reset_otp_result_model.dart';

class ForgetPasswordRemoteDataSource {
  const ForgetPasswordRemoteDataSource(this._dio);

  final Dio _dio;

  String _sanitizePhoneNumber(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  Future<SendResetOtpResultModel> sendResetOtp({
    required String phoneNumber,
  }) async {
    final sanitizedPhoneNumber = _sanitizePhoneNumber(phoneNumber);
    try {
      _logRequest(
        endpoint: '/api/otp/reset-password/send',
        body: {'phoneNumber': sanitizedPhoneNumber},
      );
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.sendResetPasswordOtp,
        data: {'phoneNumber': sanitizedPhoneNumber},
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/otp/reset-password/send', data: data);
      _logOtpIfAvailable(data);
      return SendResetOtpResultModel.fromJson(data);
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/otp/reset-password/send', error: error);
      throw _mapDioException(error);
    }
  }

  Future<VerifyResetOtpResultModel> verifyResetOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final sanitizedPhoneNumber = _sanitizePhoneNumber(phoneNumber);
    try {
      _logRequest(
        endpoint: '/api/otp/reset-password/verify',
        body: {
          'phoneNumber': sanitizedPhoneNumber,
          'code': code,
        },
      );
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.verifyResetPasswordOtp,
        data: {
          'phoneNumber': sanitizedPhoneNumber,
          'code': code,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/otp/reset-password/verify', data: data);
      return VerifyResetOtpResultModel.fromJson(data);
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/otp/reset-password/verify', error: error);
      throw _mapDioException(error);
    }
  }

  Future<ResetPasswordResultModel> resetPassword({
    required String phoneNumber,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final sanitizedPhoneNumber = _sanitizePhoneNumber(phoneNumber);
    try {
      _logRequest(
        endpoint: '/api/auth/reset-password',
        body: {
          'phoneNumber': sanitizedPhoneNumber,
          'newPassword': '******',
          'confirmPassword': '******',
        },
      );
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.resetPassword,
        data: {
          'phoneNumber': sanitizedPhoneNumber,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/auth/reset-password', data: data);
      return ResetPasswordResultModel.fromJson(data);
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/auth/reset-password', error: error);
      throw _mapDioException(error);
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

  void _logRequest({
    required String endpoint,
    required Map<String, dynamic> body,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ FORGET PASSWORD REQUEST ================');
    debugPrint('[FORGET PASSWORD API Request] $endpoint');
    debugPrint('[FORGET PASSWORD API Body] ${jsonEncode(body)}');
  }

  void _logResponse({
    required String endpoint,
    required Map<String, dynamic> data,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ FORGET PASSWORD RESPONSE ================');
    debugPrint('[FORGET PASSWORD API Response] $endpoint');
    debugPrint('[FORGET PASSWORD API Data] ${jsonEncode(data)}');
  }

  void _logDioError({
    required String endpoint,
    required DioException error,
  }) {
    if (!kDebugMode) return;
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    debugPrint('================ FORGET PASSWORD ERROR ================');
    debugPrint('[FORGET PASSWORD API Error] $endpoint');
    debugPrint('[FORGET PASSWORD API Error Status] $statusCode');
    if (responseData != null) {
      debugPrint(
          '[FORGET PASSWORD API Error Data] ${jsonEncode(responseData)}');
    } else {
      debugPrint('[FORGET PASSWORD API Error Message] ${error.message}');
    }
  }

  void _logOtpIfAvailable(Map<String, dynamic> data) {
    if (!kDebugMode) return;
    if (data.containsKey('otpCode') || data.containsKey('OtpCode')) {
      final otpCode = data['otpCode'] ?? data['OtpCode'];
      debugPrint('[FORGET PASSWORD OTP] $otpCode');
    }
  }
}
