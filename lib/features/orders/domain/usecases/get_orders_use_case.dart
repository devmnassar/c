import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/orders_page_result.dart';
import '../models/orders_query_params.dart';
import '../repositories/mobile_orders_repository.dart';

class GetOrdersUseCase {
  const GetOrdersUseCase(this._repository);

  final MobileOrdersRepository _repository;

  Future<Either<ApiException, OrdersPageResult>> call({
    OrdersQueryParams? query,
  }) {
    return _repository.getOrders(query: query);
  }
}
