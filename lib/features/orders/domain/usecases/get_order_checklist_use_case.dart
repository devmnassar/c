import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/order_checklist_question.dart';
import '../repositories/mobile_orders_repository.dart';

class GetOrderChecklistUseCase {
  const GetOrderChecklistUseCase(this._repository);

  final MobileOrdersRepository _repository;

  Future<Either<ApiException, List<OrderChecklistQuestion>>> call({
    required String orderId,
  }) {
    return _repository.getOrderChecklist(orderId: orderId);
  }
}
