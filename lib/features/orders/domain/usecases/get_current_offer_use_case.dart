import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/orders/domain/models/mobile_order_offer.dart';
import 'package:gaseel_courier/features/orders/domain/repositories/mobile_orders_repository.dart';

class GetCurrentOfferUseCase {
  const GetCurrentOfferUseCase(this._repository);

  final MobileOrdersRepository _repository;

  Future<Either<ApiException, MobileOrderOffer?>> call() {
    return _repository.getCurrentOffer();
  }
}
