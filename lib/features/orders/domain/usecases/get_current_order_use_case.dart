import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/mobile_order.dart';
import '../repositories/mobile_orders_repository.dart';

class GetCurrentOrderUseCase {
  const GetCurrentOrderUseCase(this._repository);

  final MobileOrdersRepository _repository;

  Future<Either<ApiException, MobileOrder?>> call() {
    return _repository.getCurrentOrder();
  }
}
