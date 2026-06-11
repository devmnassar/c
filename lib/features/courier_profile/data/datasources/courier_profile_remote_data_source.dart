import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/networking/api_constants.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/courier_profile/data/models/courier_profile_model.dart';

class CourierProfileRemoteDataSource {
  const CourierProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CourierProfileModel> getCourierProfile() async {
    const endpoint = '/api/courier/me';
    try {
      _logSection('REQUEST');
      _log('GET $endpoint');
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.getCourierProfile,
      );
      final data = response.data ?? <String, dynamic>{};
      _logSection('RESPONSE');
      _log('Status code: ${response.statusCode}');
      _log('Body: ${jsonEncode(data)}');
      _throwIfRequestFailed(data);
      return CourierProfileModel.fromJson(data);
    } on DioException catch (error) {
      _logSection('ERROR');
      _log('Endpoint: $endpoint');
      _log('Status code: ${error.response?.statusCode}');
      _log(
        'Error body: ${error.response?.data != null ? jsonEncode(error.response?.data) : error.message}',
      );
      throw _mapDioException(error);
    }
  }

  void _throwIfRequestFailed(Map<String, dynamic> response) {
    if (response['success'] == false) {
      throw ApiException(
        message: _extractMessage(response) ?? 'Failed to load courier profile.',
      );
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
      final rawMessage = data['message'] ?? data['Message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        return rawMessage.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }

  void _logSection(String title) {
    if (!kDebugMode) return;
    debugPrint('================ COURIER PROFILE API $title ================');
  }

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[COURIER PROFILE API] $message');
  }
}
