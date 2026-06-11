import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';
import 'package:gaseel_courier/features/orders/domain/repositories/mobile_orders_repository.dart';

class RejectOrderOfferUseCase {
  const RejectOrderOfferUseCase(this._repository);

  final MobileOrdersRepository _repository;

  Future<Either<ApiException, bool>> call(int offerId) {
    return _repository.rejectOrderOffer(offerId: offerId);
  }
}
