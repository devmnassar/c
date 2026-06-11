class GoOnlineResult {
  const GoOnlineResult({
    required this.driverId,
    required this.isOnline,
    required this.onlineSessionId,
    required this.serverTimeUtc,
    required this.nextRecommendedLocationUpdateSeconds,
    this.message,
  });

  final int driverId;
  final bool isOnline;
  final String onlineSessionId;
  final DateTime serverTimeUtc;
  final int nextRecommendedLocationUpdateSeconds;
  final String? message;
}
