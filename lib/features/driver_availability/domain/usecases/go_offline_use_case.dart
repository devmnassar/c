import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/go_offline_request.dart';
import '../entities/go_offline_result.dart';
import '../repositories/driver_availability_repository.dart';

class GoOfflineUseCase {
  const GoOfflineUseCase(this._repository);

  final DriverAvailabilityRepository _repository;

  Future<Either<ApiException, GoOfflineResult>> call(
    GoOfflineRequest request,
  ) {
    return _repository.goOffline(request);
  }
}
