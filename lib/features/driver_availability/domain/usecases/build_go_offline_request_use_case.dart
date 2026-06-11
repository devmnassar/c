import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/go_offline_request.dart';
import '../repositories/go_offline_context_repository.dart';

class BuildGoOfflineRequestUseCase {
  const BuildGoOfflineRequestUseCase(this._repository);

  final GoOfflineContextRepository _repository;

  Future<Either<ApiException, GoOfflineRequest>> call({
    required String reason,
  }) {
    return _repository.buildRequest(reason: reason);
  }
}
