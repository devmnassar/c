import 'package:gaseel_courier/features/driver_availability/domain/entities/go_offline_request.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/go_offline_result.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/go_online_request.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/go_online_result.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/heartbeat_request.dart';
import 'package:gaseel_courier/features/driver_availability/domain/entities/heartbeat_result.dart';

GoOnlineRequest sampleGoOnlineRequest() {
  return GoOnlineRequest(
    latitude: 24.7136,
    longitude: 46.6753,
    accuracy: 10,
    heading: 0,
    speed: 0,
    deviceId: 'device-test-1',
    deviceModel: 'Test Device',
    platform: 'android',
    appVersion: '1.0.0',
    batteryLevel: 80,
    isMockLocation: false,
    networkType: 'wifi',
    clientTimestampUtc: DateTime.utc(2026, 6, 7, 12, 0),
    firebaseFcmToken: 'fcm-token-test',
  );
}

GoOnlineResult sampleGoOnlineResult({
  int driverId = 42,
  bool isOnline = true,
  String onlineSessionId = 'session-online-1',
  int nextRecommendedLocationUpdateSeconds = 30,
}) {
  return GoOnlineResult(
    driverId: driverId,
    isOnline: isOnline,
    onlineSessionId: onlineSessionId,
    serverTimeUtc: DateTime.utc(2026, 6, 7, 12, 0, 1),
    nextRecommendedLocationUpdateSeconds: nextRecommendedLocationUpdateSeconds,
    message: 'Online',
  );
}

GoOfflineRequest sampleGoOfflineRequest({String reason = 'UserRequested'}) {
  return GoOfflineRequest(
    latitude: 24.7136,
    longitude: 46.6753,
    accuracy: 10,
    deviceId: 'device-test-1',
    clientTimestampUtc: DateTime.utc(2026, 6, 7, 12, 30),
    reason: reason,
  );
}

GoOfflineResult sampleGoOfflineResult({
  int driverId = 42,
  bool isOnline = false,
  String onlineSessionId = 'session-online-1',
}) {
  return GoOfflineResult(
    driverId: driverId,
    isOnline: isOnline,
    onlineSessionId: onlineSessionId,
    offlineAtUtc: DateTime.utc(2026, 6, 7, 12, 30, 1),
    message: 'Offline',
  );
}

HeartbeatRequest sampleHeartbeatRequest({bool isInternetAvailable = true}) {
  return HeartbeatRequest(
    latitude: 24.7136,
    longitude: 46.6753,
    accuracy: 10,
    heading: 0,
    speed: 0,
    deviceId: 'device-test-1',
    platform: 'android',
    appVersion: '1.0.0',
    batteryLevel: 80,
    isLocationServiceEnabled: true,
    hasLocationPermission: true,
    isInternetAvailable: isInternetAvailable,
    isMockLocation: false,
    networkType: 'wifi',
    clientTimestampUtc: DateTime.utc(2026, 6, 7, 12, 0),
  );
}

HeartbeatResult sampleHeartbeatResult({
  int driverId = 42,
  bool isOnline = true,
  bool isActive = true,
  int nextHeartbeatAfterSeconds = 30,
  bool activeSessionMissing = false,
  bool responseSucceeded = true,
  String? message = 'Heartbeat ok',
}) {
  return HeartbeatResult(
    driverId: driverId,
    isOnline: isOnline,
    isActive: isActive,
    serverTimeUtc: DateTime.utc(2026, 6, 7, 12, 0, 5),
    nextHeartbeatAfterSeconds: nextHeartbeatAfterSeconds,
    activeSessionMissing: activeSessionMissing,
    responseSucceeded: responseSucceeded,
    message: message,
  );
}
