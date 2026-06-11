import '../../domain/entities/heartbeat_request.dart';

class HeartbeatRequestModel {
  const HeartbeatRequestModel({
    required this.clientTimestampUtc,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.deviceId,
    this.platform,
    this.appVersion,
    this.firebaseFcmToken,
    this.batteryLevel,
    this.isLocationServiceEnabled,
    this.hasLocationPermission,
    this.isInternetAvailable,
    this.isMockLocation,
    this.networkType,
  });

  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final String? deviceId;
  final String? platform;
  final String? appVersion;
  final String? firebaseFcmToken;
  final int? batteryLevel;
  final bool? isLocationServiceEnabled;
  final bool? hasLocationPermission;
  final bool? isInternetAvailable;
  final bool? isMockLocation;
  final String? networkType;
  final DateTime clientTimestampUtc;

  factory HeartbeatRequestModel.fromEntity(HeartbeatRequest entity) {
    return HeartbeatRequestModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      heading: entity.heading,
      speed: entity.speed,
      deviceId: entity.deviceId,
      platform: entity.platform,
      appVersion: entity.appVersion,
      firebaseFcmToken: entity.firebaseFcmToken,
      batteryLevel: entity.batteryLevel,
      isLocationServiceEnabled: entity.isLocationServiceEnabled,
      hasLocationPermission: entity.hasLocationPermission,
      isInternetAvailable: entity.isInternetAvailable,
      isMockLocation: entity.isMockLocation,
      networkType: entity.networkType,
      clientTimestampUtc: entity.clientTimestampUtc,
    );
  }

  Map<String, dynamic> toJson() {
    final hasCoordinates = latitude != null && longitude != null;
    return <String, dynamic>{
      if (hasCoordinates) 'latitude': latitude,
      if (hasCoordinates) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (deviceId != null && deviceId!.trim().isNotEmpty) 'deviceId': deviceId,
      if (platform != null && platform!.trim().isNotEmpty) 'platform': platform,
      if (appVersion != null && appVersion!.trim().isNotEmpty)
        'appVersion': appVersion,
      if (firebaseFcmToken != null && firebaseFcmToken!.trim().isNotEmpty)
        'firebaseFcmToken': firebaseFcmToken,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (isLocationServiceEnabled != null)
        'isLocationServiceEnabled': isLocationServiceEnabled,
      if (hasLocationPermission != null)
        'hasLocationPermission': hasLocationPermission,
      if (isInternetAvailable != null)
        'isInternetAvailable': isInternetAvailable,
      if (isMockLocation != null) 'isMockLocation': isMockLocation,
      if (networkType != null && networkType!.trim().isNotEmpty)
        'networkType': networkType,
      'clientTimestampUtc': clientTimestampUtc.toUtc().toIso8601String(),
    };
  }

  String toDebugLines() {
    final buffer = StringBuffer()
      ..writeln('================ HEARTBEAT BODY ================')
      ..writeln('latitude: ${latitude ?? '(null)'}')
      ..writeln('longitude: ${longitude ?? '(null)'}')
      ..writeln('accuracy: ${accuracy ?? '(null)'}')
      ..writeln('heading: ${heading ?? '(null)'}')
      ..writeln('speed: ${speed ?? '(null)'}')
      ..writeln('deviceId: ${deviceId ?? '(null)'}')
      ..writeln('platform: ${platform ?? '(null)'}')
      ..writeln('appVersion: ${appVersion ?? '(null)'}')
      ..writeln(
        'firebaseFcmToken: ${firebaseFcmToken == null || firebaseFcmToken!.isEmpty ? '(null)' : firebaseFcmToken}',
      )
      ..writeln('batteryLevel: ${batteryLevel ?? '(null)'}')
      ..writeln(
        'isLocationServiceEnabled: ${isLocationServiceEnabled ?? '(null)'}',
      )
      ..writeln('hasLocationPermission: ${hasLocationPermission ?? '(null)'}')
      ..writeln('isInternetAvailable: ${isInternetAvailable ?? '(null)'}')
      ..writeln('isMockLocation: ${isMockLocation ?? '(null)'}')
      ..writeln('networkType: ${networkType ?? '(null)'}')
      ..writeln(
        'clientTimestampUtc: ${clientTimestampUtc.toUtc().toIso8601String()}',
      )
      ..write('===============================================');
    return buffer.toString();
  }
}
