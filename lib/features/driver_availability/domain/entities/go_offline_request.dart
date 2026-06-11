class GoOfflineRequest {
  const GoOfflineRequest({
    required this.clientTimestampUtc,
    required this.reason,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.deviceId,
  });

  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? deviceId;
  final DateTime clientTimestampUtc;
  final String reason;
}
