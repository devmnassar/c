import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/heartbeat_request.dart';
import '../repositories/heartbeat_context_repository.dart';

class BuildHeartbeatRequestUseCase {
  const BuildHeartbeatRequestUseCase(this._repository);

  final HeartbeatContextRepository _repository;

  Future<Either<ApiException, HeartbeatRequest>> call() {
    return _repository.buildRequest();
  }
}
