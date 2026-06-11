import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gaseel_courier/core/networking/api_constants.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/orders/data/models/mobile_order_model.dart';
import 'package:gaseel_courier/features/orders/data/models/mobile_order_offer_model.dart';
import 'package:gaseel_courier/features/orders/data/models/order_checklist_question_model.dart';
import 'package:gaseel_courier/features/orders/data/models/orders_page_result_model.dart';
import 'package:gaseel_courier/features/orders/data/models/proof_photo_upload_result_model.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_checklist_answer.dart';
import 'package:gaseel_courier/features/orders/domain/models/orders_query_params.dart';
import 'package:gaseel_courier/features/orders/domain/models/proof_photo_upload_result.dart';

class OrdersRemoteDataSource {
  const OrdersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<OrdersPageResultModel> getOrders({
    OrdersQueryParams? query,
  }) async {
    try {
      final queryParameters = _buildQueryParameters(query);
      _logRequest(
        endpoint: '/api/v1/mobile/orders',
        queryParameters: queryParameters,
      );
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.getOrders,
        queryParameters: queryParameters,
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/v1/mobile/orders', data: data);
      _throwIfRequestFailed(data);
      return OrdersPageResultModel.fromJson(_extractWrappedDataMap(data));
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/v1/mobile/orders', error: error);
      throw _mapDioException(error);
    }
  }

  Future<MobileOrderModel?> getCurrentOrder() async {
    try {
      _logRequest(
        endpoint: '/api/v1/mobile/orders/current',
        queryParameters: const <String, dynamic>{},
      );
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.getCurrentOrder,
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: '/api/v1/mobile/orders/current', data: data);
      _throwIfRequestFailed(data);
      final wrappedData = data['data'];
      if (wrappedData == null) {
        _logOrderFlow('Current order API returned data=null');
        return null;
      }
      if (wrappedData is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Unexpected current order response format.',
        );
      }
      _logOrderFlow(
        'Current order API summary: '
        'orderId=${wrappedData['orderId']}, '
        'orderType=${wrappedData['orderType']}, '
        'status=${wrappedData['status']}, '
        'riderStatus=${wrappedData['riderStatus']}, '
        'pickupRiderStatus=${wrappedData['pickupRiderStatus']}, '
        'distanceKm=${wrappedData['distanceKm']}, '
        'etaMinutes=${wrappedData['etaMinutes']}',
      );
      return MobileOrderModel.fromJson(wrappedData);
    } on DioException catch (error) {
      _logDioError(endpoint: '/api/v1/mobile/orders/current', error: error);
      throw _mapDioException(error);
    }
  }

  Future<MobileOrderOfferModel?> getCurrentOffer() async {
    try {
      _logRequest(
        endpoint: '/api/v1/mobile/orders/offers/current',
        queryParameters: const <String, dynamic>{},
      );
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.getCurrentOrderOffer,
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(
          endpoint: '/api/v1/mobile/orders/offers/current', data: data);
      _throwIfRequestFailed(data);
      final wrappedData = data['data'];
      if (wrappedData == null) {
        _logOrderFlow('Current offer API returned data=null');
        return null;
      }
      if (wrappedData is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Unexpected current offer response format.',
        );
      }
      _logOrderFlow(
        'Current offer API summary: '
        'offerId=${wrappedData['offerId']}, '
        'orderId=${wrappedData['orderId']}, '
        'orderType=${wrappedData['orderType']}, '
        'orderStatus=${wrappedData['orderStatus']}, '
        'remainingSeconds=${wrappedData['remainingSeconds']}, '
        'distanceKm=${wrappedData['distanceKm']}, '
        'etaMinutes=${wrappedData['etaMinutes']}',
      );
      return MobileOrderOfferModel.fromJson(wrappedData);
    } on DioException catch (error) {
      _logDioError(
          endpoint: '/api/v1/mobile/orders/offers/current', error: error);
      throw _mapDioException(error);
    }
  }

  Future<bool> acceptOrderOffer({
    required int offerId,
  }) async {
    final endpoint = '/api/v1/mobile/orders/offers/$offerId/accept';
    try {
      _logRequest(
        endpoint: endpoint,
        queryParameters: const <String, dynamic>{},
        method: 'POST',
      );
      final response = await _dio.post<dynamic>(
        ApiConstants.acceptOrderOffer(offerId),
      );
      return _parseBooleanSuccess(endpoint: endpoint, rawData: response.data);
    } on DioException catch (error) {
      _logDioError(endpoint: endpoint, error: error);
      throw _mapDioException(error);
    }
  }

  Future<bool> rejectOrderOffer({
    required int offerId,
  }) async {
    final endpoint = '/api/v1/mobile/orders/offers/$offerId/reject';
    try {
      _logRequest(
        endpoint: endpoint,
        queryParameters: const <String, dynamic>{},
        method: 'POST',
      );
      final response = await _dio.post<dynamic>(
        ApiConstants.rejectOrderOffer(offerId),
      );
      return _parseBooleanSuccess(endpoint: endpoint, rawData: response.data);
    } on DioException catch (error) {
      _logDioError(endpoint: endpoint, error: error);
      throw _mapDioException(error);
    }
  }

  Future<bool> updateRiderStatus({
    required String orderId,
    required int status,
  }) async {
    final endpoint = '/api/v1/mobile/orders/$orderId/delivery-status';
    final body = <String, dynamic>{'status': status};
    try {
      _logRiderStatusFlow(
        'Preparing update for orderId=$orderId '
        'status=$status (${_describeRiderStatus(status)})',
      );
      _logRequest(
        endpoint: endpoint,
        queryParameters: const <String, dynamic>{},
        method: 'PUT',
        body: body,
      );
      final response = await _dio.put<dynamic>(
        ApiConstants.updateRiderStatus(orderId),
        data: body,
      );
      final rawData = response.data;
      _logRiderStatusFlow(
        'HTTP ${response.statusCode} received for orderId=$orderId '
        'status=$status (${_describeRiderStatus(status)})',
      );
      _logRawResponse(endpoint: endpoint, data: rawData);

      if (rawData is Map<String, dynamic>) {
        _throwIfRequestFailed(rawData);
        final wrappedData = rawData['data'];
        if (wrappedData is bool) {
          _logRiderStatusFlow(
            'Parsed response data bool=$wrappedData '
            'for orderId=$orderId status=$status',
          );
          return wrappedData;
        }
        _logRiderStatusFlow(
          'Parsed wrapped map response success=${rawData['success'] == true} '
          'for orderId=$orderId status=$status',
        );
        return rawData['success'] == true;
      }

      if (rawData is bool) {
        _logRiderStatusFlow(
          'Parsed raw bool response=$rawData '
          'for orderId=$orderId status=$status',
        );
        return rawData;
      }

      _logRiderStatusFlow(
        'Response shape had no explicit bool; defaulting to success=true '
        'for orderId=$orderId status=$status',
      );
      return true;
    } on DioException catch (error) {
      _logRiderStatusFlow(
        'DioException while updating orderId=$orderId '
        'status=$status (${_describeRiderStatus(status)})',
      );
      _logDioError(endpoint: endpoint, error: error);
      throw _mapDioException(error);
    }
  }

  Future<bool> updatePickupStatus({
    required String orderId,
    required int status,
  }) async {
    final endpoint = '/api/v1/mobile/orders/$orderId/pickup-status';
    final body = <String, dynamic>{'status': status};
    try {
      _logRiderStatusFlow(
        'Preparing pickup update for orderId=$orderId '
        'status=$status (${_describePickupStatus(status)})',
      );
      _logRequest(
        endpoint: endpoint,
        queryParameters: const <String, dynamic>{},
        method: 'PUT',
        body: body,
      );
      final response = await _dio.put<dynamic>(
        ApiConstants.updatePickupStatus(orderId),
        data: body,
      );
      final rawData = response.data;
      _logRiderStatusFlow(
        'HTTP ${response.statusCode} received for pickup orderId=$orderId '
        'status=$status (${_describePickupStatus(status)})',
      );
      _logRawResponse(endpoint: endpoint, data: rawData);

      if (rawData is Map<String, dynamic>) {
        _throwIfRequestFailed(rawData);
        final wrappedData = rawData['data'];
        if (wrappedData is bool) {
          return wrappedData;
        }
        return rawData['success'] == true;
      }

      if (rawData is bool) {
        return rawData;
      }

      return true;
    } on DioException catch (error) {
      _logRiderStatusFlow(
        'DioException while updating pickup orderId=$orderId '
        'status=$status (${_describePickupStatus(status)})',
      );
      _logDioError(endpoint: endpoint, error: error);
      throw _mapDioException(error);
    }
  }

  Future<List<OrderChecklistQuestionModel>> getOrderChecklist({
    required String orderId,
  }) async {
    final endpoint = '/api/mobile/orders/$orderId/checklist';
    try {
      _logRequest(
        endpoint: endpoint,
        queryParameters: const <String, dynamic>{},
      );
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.getOrderChecklist(orderId),
      );
      final data = response.data ?? <String, dynamic>{};
      _logResponse(endpoint: endpoint, data: data);
      _throwIfRequestFailed(data);

      final wrappedData = data['data'];
      if (wrappedData is! List) {
        throw const ApiException(
          message: 'Unexpected checklist response format.',
        );
      }

      return wrappedData
          .whereType<Map<String, dynamic>>()
          .map(OrderChecklistQuestionModel.fromJson)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    } on DioException catch (error) {
      _logDioError(endpoint: endpoint, error: error);
      throw _mapDioException(error);
    }
  }

  Future<bool> submitOrderChecklist({
    required String orderId,
    required List<OrderChecklistAnswer> answers,
  }) async {
    final endpoint = '/api/mobile/orders/$orderId/checklist';
    final body = <String, dynamic>{
      'answers': answers
          .map(
            (item) => <String, dynamic>{
              'questionId': item.questionId,
              'answer': item.answer,
            },
          )
          .toList(),
    };

    try {
      _logRequest(
        endpoint: endpoint,
        queryParameters: const <String, dynamic>{},
        method: 'POST',
        body: body,
      );
      final response = await _dio.post<dynamic>(
        ApiConstants.submitOrderChecklist(orderId),
        data: body,
      );
      return _parseBooleanSuccess(endpoint: endpoint, rawData: response.data);
    } on DioException catch (error) {
      _logDioError(endpoint: endpoint, error: error);
      throw _mapDioException(error);
    }
  }

  Future<ProofPhotoUploadResultModel> uploadProofPhoto({
    required String orderId,
    required String filePath,
    required ProofPhotoType photoType,
    double? latitude,
    double? longitude,
  }) async {
    final endpoint = '/api/v1/mobile/orders/$orderId/proof-photo';
    final body = <String, dynamic>{
      'file': filePath,
      'photoType': photoType.value,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    try {
      _logProofPhotoFlow(
        'Preparing upload for orderId=$orderId '
        'photoType=${photoType.value} (${_describeProofPhotoType(photoType)})',
      );
      _logRequest(
        endpoint: endpoint,
        queryParameters: const <String, dynamic>{},
        method: 'POST',
        body: body,
      );

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'photoType': photoType.value,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.uploadProofPhoto(orderId),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      final data = response.data ?? <String, dynamic>{};
      _logProofPhotoFlow(
        'HTTP ${response.statusCode} received for proof-photo '
        'orderId=$orderId photoType=${photoType.value}',
      );
      _logResponse(endpoint: endpoint, data: data);
      _throwIfRequestFailed(data);

      final wrappedData = data['data'];
      if (wrappedData is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Unexpected proof photo response format.',
        );
      }

      return ProofPhotoUploadResultModel.fromJson(wrappedData);
    } on DioException catch (error) {
      _logProofPhotoFlow(
        'DioException while uploading proof photo for orderId=$orderId '
        'photoType=${photoType.value} (${_describeProofPhotoType(photoType)})',
      );
      _logDioError(endpoint: endpoint, error: error);
      throw _mapDioException(error);
    }
  }

  Map<String, dynamic> _buildQueryParameters(OrdersQueryParams? query) {
    if (query == null) {
      return const <String, dynamic>{};
    }

    return <String, dynamic>{
      if (query.page != null) 'page': query.page,
      if (query.pageSize != null) 'pageSize': query.pageSize,
      if ((query.orderNumber ?? '').trim().isNotEmpty)
        'orderNumber': query.orderNumber!.trim(),
      if ((query.customerName ?? '').trim().isNotEmpty)
        'customerName': query.customerName!.trim(),
      if (query.status != null) 'status': query.status,
      if (query.orderType != null) 'orderType': query.orderType,
      if (query.fromDate != null) 'fromDate': query.fromDate!.toIso8601String(),
      if (query.toDate != null) 'toDate': query.toDate!.toIso8601String(),
    };
  }

  Map<String, dynamic> _extractWrappedDataMap(Map<String, dynamic> response) {
    final wrappedData = response['data'];
    if (wrappedData is Map<String, dynamic>) {
      return wrappedData;
    }

    throw const ApiException(message: 'Unexpected orders response format.');
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

  void _throwIfRequestFailed(Map<String, dynamic> response) {
    final success = response['success'];
    if (success == false) {
      throw ApiException(
        message: _extractMessage(response) ?? 'Request failed.',
      );
    }
  }

  void _logRequest({
    required String endpoint,
    required Map<String, dynamic> queryParameters,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ ORDERS REQUEST ================');
    debugPrint('[ORDERS API Request] $method $endpoint');
    debugPrint('[ORDERS API Query] ${jsonEncode(queryParameters)}');
    if (body != null) {
      debugPrint('[ORDERS API Body] ${jsonEncode(body)}');
    }
  }

  void _logResponse({
    required String endpoint,
    required Map<String, dynamic> data,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ ORDERS RESPONSE ================');
    debugPrint('[ORDERS API Response] $endpoint');
    debugPrint('[ORDERS API Data] ${jsonEncode(data)}');
  }

  void _logRawResponse({
    required String endpoint,
    required dynamic data,
  }) {
    if (!kDebugMode) return;
    debugPrint('================ ORDERS RESPONSE ================');
    debugPrint('[ORDERS API Response] $endpoint');
    debugPrint('[ORDERS API Data] ${jsonEncode(data)}');
  }

  void _logDioError({
    required String endpoint,
    required DioException error,
  }) {
    if (!kDebugMode) return;
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    debugPrint('================ ORDERS ERROR ================');
    debugPrint('[ORDERS API Error] $endpoint');
    debugPrint('[ORDERS API Error Status] $statusCode');
    if (responseData != null) {
      debugPrint('[ORDERS API Error Data] ${jsonEncode(responseData)}');
    } else {
      debugPrint('[ORDERS API Error Message] ${error.message}');
    }
  }

  void _logRiderStatusFlow(String message) {
    if (!kDebugMode) return;
    debugPrint('================ RIDER STATUS FLOW ================');
    debugPrint('[RIDER STATUS FLOW] $message');
  }

  void _logProofPhotoFlow(String message) {
    if (!kDebugMode) return;
    debugPrint('================ PROOF PHOTO FLOW ================');
    debugPrint('[PROOF PHOTO FLOW] $message');
  }

  void _logOrderFlow(String message) {
    if (!kDebugMode) return;
    debugPrint('================ ORDERS FLOW ================');
    debugPrint('[ORDERS FLOW] $message');
  }

  String _describeRiderStatus(int status) {
    switch (status) {
      case 1:
        return 'EnRouteToLaundry';
      case 2:
        return 'ArrivedAtLaundry';
      case 3:
        return 'PickedUp';
      case 4:
        return 'EnRouteToCustomer';
      case 5:
        return 'ArrivedAtCustomer';
      case 6:
        return 'Delivered';
      case 7:
        return 'AttemptedDelivery';
      default:
        return 'Unknown';
    }
  }

  String _describeProofPhotoType(ProofPhotoType photoType) {
    switch (photoType) {
      case ProofPhotoType.pickupProof:
        return 'PickupProof';
      case ProofPhotoType.deliveryProof:
        return 'DeliveryProof';
      case ProofPhotoType.attemptedDeliveryProof:
        return 'AttemptedDeliveryProof';
      case ProofPhotoType.laundryDropoffProof:
        return 'LaundryDropoffProof';
    }
  }

  String _describePickupStatus(int status) {
    switch (status) {
      case 1:
        return 'EnRouteToCustomer';
      case 2:
        return 'ArrivedAtCustomer';
      case 3:
        return 'PickedUp';
      case 4:
        return 'EnRouteToLaundry';
      case 5:
        return 'ArrivedAtLaundry';
      case 6:
        return 'DroppedOffAtLaundry';
      default:
        return 'Unknown';
    }
  }

  bool _parseBooleanSuccess({
    required String endpoint,
    required dynamic rawData,
  }) {
    _logRawResponse(endpoint: endpoint, data: rawData);

    if (rawData is Map<String, dynamic>) {
      _throwIfRequestFailed(rawData);
      final wrappedData = rawData['data'];
      if (wrappedData is bool) {
        return wrappedData;
      }
      return rawData['success'] == true;
    }

    if (rawData is bool) {
      return rawData;
    }

    return true;
  }
}
