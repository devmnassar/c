import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/heartbeat_request.dart';
import '../entities/heartbeat_result.dart';
import '../repositories/driver_availability_repository.dart';

class HeartbeatUseCase {
  const HeartbeatUseCase(this._repository);

  final DriverAvailabilityRepository _repository;

  Future<Either<ApiException, HeartbeatResult>> call(
    HeartbeatRequest request,
  ) {
    return _repository.heartbeat(request);
  }
}
