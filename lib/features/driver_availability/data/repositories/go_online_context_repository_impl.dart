import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../../domain/entities/go_online_request.dart';
import '../../domain/repositories/go_online_context_repository.dart';
import '../datasources/go_online_context_local_data_source.dart';

class GoOnlineContextRepositoryImpl implements GoOnlineContextRepository {
  const GoOnlineContextRepositoryImpl(this._localDataSource);

  final GoOnlineContextLocalDataSource _localDataSource;

  @override
  Future<Either<ApiException, GoOnlineRequest>> buildRequest() async {
    try {
      final positionFuture = _localDataSource.getCurrentPosition();
      final nativeSnapshotFuture = _localDataSource.getNativeSnapshot();
      final appVersionFuture = _localDataSource.getAppVersion();
      final firebaseFcmTokenFuture = _localDataSource.getFirebaseFcmToken();

      final position = await positionFuture;
      final nativeSnapshot = await nativeSnapshotFuture;
      final appVersion = await appVersionFuture;
      final firebaseFcmToken = await firebaseFcmTokenFuture;

      return right(
        GoOnlineRequest(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          heading: position.heading,
          speed: position.speed,
          deviceId: nativeSnapshot.deviceId,
          deviceModel: nativeSnapshot.deviceModel,
          platform: _localDataSource.getPlatformName(),
          appVersion: appVersion,
          firebaseFcmToken: firebaseFcmToken,
          batteryLevel: nativeSnapshot.batteryLevel,
          isMockLocation: position.isMocked,
          networkType: nativeSnapshot.networkType,
          clientTimestampUtc: DateTime.now().toUtc(),
        ),
      );
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(
          message: 'Unable to prepare go-online request data.',
        ),
      );
    }
  }
}
