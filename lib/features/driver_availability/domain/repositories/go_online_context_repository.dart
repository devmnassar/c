import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/go_online_request.dart';

abstract class GoOnlineContextRepository {
  Future<Either<ApiException, GoOnlineRequest>> buildRequest();
}
