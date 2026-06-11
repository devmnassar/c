import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../../domain/entities/go_offline_request.dart';
import '../../domain/repositories/go_offline_context_repository.dart';
import '../datasources/go_online_context_local_data_source.dart';

class GoOfflineContextRepositoryImpl implements GoOfflineContextRepository {
  const GoOfflineContextRepositoryImpl(this._localDataSource);

  final GoOnlineContextLocalDataSource _localDataSource;

  @override
  Future<Either<ApiException, GoOfflineRequest>> buildRequest({
    required String reason,
  }) async {
    try {
      final position =
          await _localDataSource.getOptionalCurrentOrLastKnownPosition();
      final deviceId = await _localDataSource.getOptionalDeviceId();

      return right(
        GoOfflineRequest(
          latitude: position?.latitude,
          longitude: position?.longitude,
          accuracy: position?.accuracy,
          deviceId: deviceId,
          clientTimestampUtc: DateTime.now().toUtc(),
          reason: reason,
        ),
      );
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(
          message: 'Unable to prepare go-offline request data.',
        ),
      );
    }
  }
}
