import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/networking/api_constants.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/go_offline_request_model.dart';
import '../models/go_offline_result_model.dart';
import '../models/heartbeat_request_model.dart';
import '../models/heartbeat_result_model.dart';
import '../models/go_online_request_model.dart';
import '../models/go_online_result_model.dart';

class DriverAvailabilityRemoteDataSource {
  const DriverAvailabilityRemoteDataSource(this._dio);

  final Dio _dio;

  Future<GoOnlineResultModel> goOnline(GoOnlineRequestModel request) async {
    try {
      final payload = request.toJson();
      _logRequestStart(
        payload,
        endpoint: ApiConstants.goOnline,
        label: 'GO ONLINE',
      );
      _logRequestFields(request);
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.goOnline,
        data: payload,
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(
        response.statusCode,
        data,
        endpoint: ApiConstants.goOnline,
        label: 'GO ONLINE',
      );
      _throwIfRequestFailed(data);
      final wrapped = _extractEnvelopeData(data);
      if (wrapped is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Unexpected go-online response format.',
        );
      }
      return GoOnlineResultModel.fromJson(
        wrapped,
        message: _extractMessage(data),
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<GoOfflineResultModel> goOffline(GoOfflineRequestModel request) async {
    try {
      final payload = request.toJson();
      _logRequestStart(payload,
          endpoint: ApiConstants.goOffline, label: 'GO OFFLINE');
      _logDebugBody(request.toDebugLines());
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.goOffline,
        data: payload,
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(
        response.statusCode,
        data,
        endpoint: ApiConstants.goOffline,
        label: 'GO OFFLINE',
      );
      _throwIfRequestFailed(data);
      final wrapped = _extractEnvelopeData(data);
      if (wrapped is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Unexpected go-offline response format.',
        );
      }
      return GoOfflineResultModel.fromJson(
        wrapped,
        message: _extractMessage(data) ?? _extractMessage(wrapped),
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<HeartbeatResultModel> heartbeat(HeartbeatRequestModel request) async {
    try {
      final payload = request.toJson();
      _logRequestStart(
        payload,
        endpoint: ApiConstants.heartbeat,
        label: 'HEARTBEAT',
      );
      _logDebugBody(request.toDebugLines());
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.heartbeat,
        data: payload,
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(
        response.statusCode,
        data,
        endpoint: ApiConstants.heartbeat,
        label: 'HEARTBEAT',
      );

      if (_extractEnvelopeData(data) is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Unexpected heartbeat response format.',
        );
      }

      return HeartbeatResultModel.fromEnvelope(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  ApiException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    _logDioError(error);
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

  void _throwIfRequestFailed(Map<String, dynamic> response) {
    if (response['success'] == false) {
      throw ApiException(
        message: _extractMessage(response) ?? 'Request failed.',
      );
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final rawMessage = data['message'] ?? data['Message'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        return rawMessage.trim();
      }

      final nestedData = data['data'] ?? data['Data'];
      if (nestedData is Map<String, dynamic>) {
        final nestedMessage = nestedData['message'] ?? nestedData['Message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage.trim();
        }
      }

      final errors = data['errors'] ?? data['Errors'];
      final extractedError = _extractValidationMessage(errors);
      if (extractedError != null) {
        return extractedError;
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }

  String? _extractValidationMessage(dynamic errors) {
    if (errors is Map) {
      for (final value in errors.values) {
        final message = _extractValidationMessage(value);
        if (message != null) {
          return message;
        }
      }
      return null;
    }
    if (errors is List) {
      for (final item in errors) {
        final message = _extractValidationMessage(item);
        if (message != null) {
          return message;
        }
      }
      return null;
    }
    if (errors is String && errors.trim().isNotEmpty) {
      return errors.trim();
    }
    return null;
  }

  dynamic _extractEnvelopeData(Map<String, dynamic> response) {
    return response['data'] ?? response['Data'];
  }

  void _logRequestStart(
    Map<String, dynamic> payload, {
    required String endpoint,
    required String label,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ $label API REQUEST START ================');
    debugPrint('[$label API Request] $endpoint');
    debugPrint('[$label API Body] ${jsonEncode(payload)}');
  }

  void _logRequestFields(GoOnlineRequestModel request) {
    if (!kDebugMode) return;
    debugPrint(request.toDebugLines());
  }

  void _logDebugBody(String body) {
    if (!kDebugMode) return;
    debugPrint(body);
  }

  void _logResponse(
    int? statusCode,
    Map<String, dynamic> data, {
    required String endpoint,
    required String label,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ $label API RESPONSE ================');
    debugPrint('[$label API Response] $endpoint');
    debugPrint('[$label API Status Code] ${statusCode ?? 'unknown'}');
    debugPrint('[$label API Data] ${jsonEncode(data)}');
    debugPrint('================ $label API RESPONSE END ================');
  }

  void _logDioError(DioException error) {
    if (!kDebugMode) return;
    debugPrint(
        '================ DRIVER AVAILABILITY API ERROR ================');
    debugPrint('[API ERROR Type] ${error.type.name}');
    debugPrint('[API ERROR Path] ${error.requestOptions.path}');
    debugPrint(
      '[API ERROR Status Code] ${error.response?.statusCode ?? 'unknown'}',
    );
    if (error.requestOptions.data != null) {
      debugPrint(
        '[API ERROR Request Body] ${jsonEncode(error.requestOptions.data)}',
      );
    }
    final responseData = error.response?.data;
    if (responseData != null) {
      debugPrint('[API ERROR Response] ${jsonEncode(responseData)}');
    }
    debugPrint('[API ERROR Message] ${error.message}');
    debugPrint(
        '================================================================');
  }
}
