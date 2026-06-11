import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/go_online_request.dart';
import '../entities/go_online_result.dart';
import '../repositories/driver_availability_repository.dart';

class GoOnlineUseCase {
  const GoOnlineUseCase(this._repository);

  final DriverAvailabilityRepository _repository;

  Future<Either<ApiException, GoOnlineResult>> call(
    GoOnlineRequest request,
  ) {
    return _repository.goOnline(request);
  }
}
