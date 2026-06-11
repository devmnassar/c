import '../../domain/entities/go_online_request.dart';

class GoOnlineRequestModel {
  const GoOnlineRequestModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.heading,
    required this.speed,
    required this.deviceId,
    required this.deviceModel,
    required this.platform,
    required this.appVersion,
    required this.batteryLevel,
    required this.isMockLocation,
    required this.networkType,
    required this.clientTimestampUtc,
    this.firebaseFcmToken,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final double heading;
  final double speed;
  final String deviceId;
  final String deviceModel;
  final String platform;
  final String appVersion;
  final String? firebaseFcmToken;
  final int batteryLevel;
  final bool isMockLocation;
  final String networkType;
  final DateTime clientTimestampUtc;

  factory GoOnlineRequestModel.fromEntity(GoOnlineRequest entity) {
    return GoOnlineRequestModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      heading: entity.heading,
      speed: entity.speed,
      deviceId: entity.deviceId,
      deviceModel: entity.deviceModel,
      platform: entity.platform,
      appVersion: entity.appVersion,
      firebaseFcmToken: entity.firebaseFcmToken,
      batteryLevel: entity.batteryLevel,
      isMockLocation: entity.isMockLocation,
      networkType: entity.networkType,
      clientTimestampUtc: entity.clientTimestampUtc,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'platform': platform,
      'appVersion': appVersion,
      if (firebaseFcmToken != null && firebaseFcmToken!.trim().isNotEmpty)
        'firebaseFcmToken': firebaseFcmToken,
      'batteryLevel': batteryLevel,
      'isMockLocation': isMockLocation,
      'networkType': networkType,
      'clientTimestampUtc': clientTimestampUtc.toUtc().toIso8601String(),
    };
  }

  String toDebugLines() {
    final buffer = StringBuffer()
      ..writeln('================ GO ONLINE BODY ================')
      ..writeln('latitude: $latitude')
      ..writeln('longitude: $longitude')
      ..writeln('accuracy: $accuracy')
      ..writeln('heading: $heading')
      ..writeln('speed: $speed')
      ..writeln('deviceId: $deviceId')
      ..writeln('deviceModel: $deviceModel')
      ..writeln('platform: $platform')
      ..writeln('appVersion: $appVersion')
      ..writeln(
        'firebaseFcmToken: ${firebaseFcmToken == null || firebaseFcmToken!.isEmpty ? '(null)' : firebaseFcmToken}',
      )
      ..writeln('batteryLevel: $batteryLevel')
      ..writeln('isMockLocation: $isMockLocation')
      ..writeln('networkType: $networkType')
      ..writeln(
        'clientTimestampUtc: ${clientTimestampUtc.toUtc().toIso8601String()}',
      )
      ..write('================================================');
    return buffer.toString();
  }
}
