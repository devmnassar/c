import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:gaseel_courier/features/orders/domain/models/mobile_order.dart';
import 'package:gaseel_courier/features/orders/domain/models/mobile_order_offer.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_checklist_answer.dart';
import 'package:gaseel_courier/features/orders/domain/models/order_checklist_question.dart';
import 'package:gaseel_courier/features/orders/domain/models/orders_page_result.dart';
import 'package:gaseel_courier/features/orders/domain/models/orders_query_params.dart';
import 'package:gaseel_courier/features/orders/domain/models/proof_photo_upload_result.dart';
import 'package:gaseel_courier/features/orders/domain/repositories/mobile_orders_repository.dart';

class MobileOrdersRepositoryImpl implements MobileOrdersRepository {
  const MobileOrdersRepositoryImpl(this._remoteDataSource);

  final OrdersRemoteDataSource _remoteDataSource;

  @override
  Future<Either<ApiException, OrdersPageResult>> getOrders({
    OrdersQueryParams? query,
  }) async {
    try {
      final model = await _remoteDataSource.getOrders(query: query);
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, MobileOrder?>> getCurrentOrder() async {
    try {
      final model = await _remoteDataSource.getCurrentOrder();
      return right(model?.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, MobileOrderOffer?>> getCurrentOffer() async {
    try {
      final model = await _remoteDataSource.getCurrentOffer();
      return right(model?.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, bool>> acceptOrderOffer({
    required int offerId,
  }) async {
    try {
      final result = await _remoteDataSource.acceptOrderOffer(offerId: offerId);
      return right(result);
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, bool>> rejectOrderOffer({
    required int offerId,
  }) async {
    try {
      final result = await _remoteDataSource.rejectOrderOffer(offerId: offerId);
      return right(result);
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, bool>> updateRiderStatus({
    required String orderId,
    required int status,
  }) async {
    try {
      final result = await _remoteDataSource.updateRiderStatus(
        orderId: orderId,
        status: status,
      );
      return right(result);
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, bool>> updatePickupStatus({
    required String orderId,
    required int status,
  }) async {
    try {
      final result = await _remoteDataSource.updatePickupStatus(
        orderId: orderId,
        status: status,
      );
      return right(result);
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, List<OrderChecklistQuestion>>> getOrderChecklist({
    required String orderId,
  }) async {
    try {
      final result = await _remoteDataSource.getOrderChecklist(orderId: orderId);
      return right(result.map((item) => item.toEntity()).toList(growable: false));
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, bool>> submitOrderChecklist({
    required String orderId,
    required List<OrderChecklistAnswer> answers,
  }) async {
    try {
      final result = await _remoteDataSource.submitOrderChecklist(
        orderId: orderId,
        answers: answers,
      );
      return right(result);
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, ProofPhotoUploadResult>> uploadProofPhoto({
    required String orderId,
    required String filePath,
    required ProofPhotoType photoType,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await _remoteDataSource.uploadProofPhoto(
        orderId: orderId,
        filePath: filePath,
        photoType: photoType,
        latitude: latitude,
        longitude: longitude,
      );
      return right(result.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }
}
