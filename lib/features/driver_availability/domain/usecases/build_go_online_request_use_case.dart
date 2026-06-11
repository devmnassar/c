import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/go_online_request.dart';
import '../repositories/go_online_context_repository.dart';

class BuildGoOnlineRequestUseCase {
  const BuildGoOnlineRequestUseCase(this._repository);

  final GoOnlineContextRepository _repository;

  Future<Either<ApiException, GoOnlineRequest>> call() {
    return _repository.buildRequest();
  }
}
