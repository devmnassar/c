import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/order_checklist_answer.dart';
import '../repositories/mobile_orders_repository.dart';

class SubmitOrderChecklistUseCase {
  const SubmitOrderChecklistUseCase(this._repository);

  final MobileOrdersRepository _repository;

  Future<Either<ApiException, bool>> call({
    required String orderId,
    required List<OrderChecklistAnswer> answers,
  }) {
    return _repository.submitOrderChecklist(
      orderId: orderId,
      answers: answers,
    );
  }
}
