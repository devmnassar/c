import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../../domain/entities/go_online_request.dart';
import '../../domain/entities/go_online_result.dart';
import '../../domain/entities/go_offline_request.dart';
import '../../domain/entities/go_offline_result.dart';
import '../../domain/entities/heartbeat_request.dart';
import '../../domain/entities/heartbeat_result.dart';
import '../../domain/repositories/driver_availability_repository.dart';
import '../datasources/driver_availability_remote_data_source.dart';
import '../models/heartbeat_request_model.dart';
import '../models/go_offline_request_model.dart';
import '../models/go_online_request_model.dart';

class DriverAvailabilityRepositoryImpl implements DriverAvailabilityRepository {
  const DriverAvailabilityRepositoryImpl(this._remoteDataSource);

  final DriverAvailabilityRemoteDataSource _remoteDataSource;

  @override
  Future<Either<ApiException, GoOnlineResult>> goOnline(
    GoOnlineRequest request,
  ) async {
    try {
      final model = await _remoteDataSource.goOnline(
        GoOnlineRequestModel.fromEntity(request),
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, GoOfflineResult>> goOffline(
    GoOfflineRequest request,
  ) async {
    try {
      final model = await _remoteDataSource.goOffline(
        GoOfflineRequestModel.fromEntity(request),
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, HeartbeatResult>> heartbeat(
    HeartbeatRequest request,
  ) async {
    try {
      final model = await _remoteDataSource.heartbeat(
        HeartbeatRequestModel.fromEntity(request),
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }
}
