class HeartbeatRequest {
  const HeartbeatRequest({
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
}
