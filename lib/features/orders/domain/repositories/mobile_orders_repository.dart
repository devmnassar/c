import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/mobile_order.dart';
import '../models/mobile_order_offer.dart';
import '../models/order_checklist_answer.dart';
import '../models/order_checklist_question.dart';
import '../models/orders_page_result.dart';
import '../models/orders_query_params.dart';
import '../models/proof_photo_upload_result.dart';

abstract class MobileOrdersRepository {
  Future<Either<ApiException, OrdersPageResult>> getOrders({
    OrdersQueryParams? query,
  });

  Future<Either<ApiException, MobileOrder?>> getCurrentOrder();

  Future<Either<ApiException, MobileOrderOffer?>> getCurrentOffer();

  Future<Either<ApiException, bool>> acceptOrderOffer({
    required int offerId,
  });

  Future<Either<ApiException, bool>> rejectOrderOffer({
    required int offerId,
  });

  Future<Either<ApiException, bool>> updateRiderStatus({
    required String orderId,
    required int status,
  });

  Future<Either<ApiException, bool>> updatePickupStatus({
    required String orderId,
    required int status,
  });

  Future<Either<ApiException, List<OrderChecklistQuestion>>> getOrderChecklist({
    required String orderId,
  });

  Future<Either<ApiException, bool>> submitOrderChecklist({
    required String orderId,
    required List<OrderChecklistAnswer> answers,
  });

  Future<Either<ApiException, ProofPhotoUploadResult>> uploadProofPhoto({
    required String orderId,
    required String filePath,
    required ProofPhotoType photoType,
    double? latitude,
    double? longitude,
  });
}
