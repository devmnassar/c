class GoOfflineResult {
  const GoOfflineResult({
    required this.driverId,
    required this.isOnline,
    required this.onlineSessionId,
    required this.offlineAtUtc,
    this.message,
  });

  final int driverId;
  final bool isOnline;
  final String onlineSessionId;
  final DateTime? offlineAtUtc;
  final String? message;
}
