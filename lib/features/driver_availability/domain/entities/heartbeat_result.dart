class HeartbeatResult {
  const HeartbeatResult({
    required this.driverId,
    required this.isOnline,
    required this.isActive,
    required this.serverTimeUtc,
    required this.nextHeartbeatAfterSeconds,
    required this.activeSessionMissing,
    required this.responseSucceeded,
    this.message,
  });

  final int driverId;
  final bool isOnline;
  final bool isActive;
  final DateTime serverTimeUtc;
  final int nextHeartbeatAfterSeconds;
  final bool activeSessionMissing;
  final bool responseSucceeded;
  final String? message;
}
