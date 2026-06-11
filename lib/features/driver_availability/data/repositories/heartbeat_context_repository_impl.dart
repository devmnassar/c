import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../../domain/entities/heartbeat_request.dart';
import '../../domain/repositories/heartbeat_context_repository.dart';
import '../datasources/go_online_context_local_data_source.dart';

class HeartbeatContextRepositoryImpl implements HeartbeatContextRepository {
  const HeartbeatContextRepositoryImpl(this._localDataSource);

  final GoOnlineContextLocalDataSource _localDataSource;

  @override
  Future<Either<ApiException, HeartbeatRequest>> buildRequest() async {
    try {
      final position =
          await _localDataSource.getOptionalCurrentOrLastKnownPosition();
      final nativeSnapshot = await _localDataSource.getOptionalNativeSnapshot();
      final appVersion = await _localDataSource.getOptionalAppVersion();
      final firebaseFcmToken =
          await _localDataSource.getOptionalFirebaseFcmToken();
      final isLocationServiceEnabled =
          await _localDataSource.isLocationServiceEnabled();
      final hasLocationPermission =
          await _localDataSource.hasLocationPermission();

      final networkType = nativeSnapshot?.networkType;
      final isInternetAvailable = networkType == null
          ? null
          : (networkType != 'none' && networkType != 'unknown');

      return right(
        HeartbeatRequest(
          latitude: position?.latitude,
          longitude: position?.longitude,
          accuracy: position?.accuracy,
          heading: position?.heading,
          speed: position?.speed,
          deviceId: nativeSnapshot?.deviceId,
          platform: _localDataSource.getPlatformName(),
          appVersion: appVersion,
          firebaseFcmToken: firebaseFcmToken,
          batteryLevel: nativeSnapshot?.batteryLevel,
          isLocationServiceEnabled: isLocationServiceEnabled,
          hasLocationPermission: hasLocationPermission,
          isInternetAvailable: isInternetAvailable,
          isMockLocation: position?.isMocked,
          networkType: networkType,
          clientTimestampUtc: DateTime.now().toUtc(),
        ),
      );
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(
          message: 'Unable to prepare heartbeat request data.',
        ),
      );
    }
  }
}
