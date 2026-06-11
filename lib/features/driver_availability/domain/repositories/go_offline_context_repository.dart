import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/go_offline_request.dart';

abstract class GoOfflineContextRepository {
  Future<Either<ApiException, GoOfflineRequest>> buildRequest({
    required String reason,
  });
}
