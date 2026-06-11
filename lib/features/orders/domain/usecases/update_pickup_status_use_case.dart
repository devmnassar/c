import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../repositories/mobile_orders_repository.dart';

class UpdatePickupStatusUseCase {
  const UpdatePickupStatusUseCase(this._repository);

  final MobileOrdersRepository _repository;

  Future<Either<ApiException, bool>> call({
    required String orderId,
    required int status,
  }) {
    return _repository.updatePickupStatus(
      orderId: orderId,
      status: status,
    );
  }
}
