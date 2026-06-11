import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/go_online_request.dart';
import '../entities/go_online_result.dart';
import '../entities/go_offline_request.dart';
import '../entities/go_offline_result.dart';
import '../entities/heartbeat_request.dart';
import '../entities/heartbeat_result.dart';

abstract class DriverAvailabilityRepository {
  Future<Either<ApiException, GoOnlineResult>> goOnline(
    GoOnlineRequest request,
  );

  Future<Either<ApiException, GoOfflineResult>> goOffline(
    GoOfflineRequest request,
  );

  Future<Either<ApiException, HeartbeatResult>> heartbeat(
    HeartbeatRequest request,
  );
}
