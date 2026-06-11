class GoOnlineRequest {
  const GoOnlineRequest({
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
}
