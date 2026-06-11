import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/heartbeat_request.dart';

abstract class HeartbeatContextRepository {
  Future<Either<ApiException, HeartbeatRequest>> buildRequest();
}
