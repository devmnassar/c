import '../../domain/entities/heartbeat_result.dart';

class HeartbeatResultModel {
  const HeartbeatResultModel({
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

  factory HeartbeatResultModel.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'] ?? envelope['Data'];
    final wrapped = data is Map<String, dynamic> ? data : <String, dynamic>{};
    return HeartbeatResultModel(
      driverId: _readInt(wrapped['driverId']),
      isOnline: wrapped['isOnline'] == true,
      isActive: wrapped['isActive'] == true,
      serverTimeUtc: DateTime.tryParse(
            (wrapped['serverTimeUtc'] as String?)?.trim() ?? '',
          ) ??
          DateTime.now().toUtc(),
      nextHeartbeatAfterSeconds: _readInt(wrapped['nextHeartbeatAfterSeconds']),
      activeSessionMissing: wrapped['activeSessionMissing'] == true,
      responseSucceeded: envelope['success'] == true,
      message: _readMessage(envelope, wrapped),
    );
  }

  HeartbeatResult toEntity() {
    return HeartbeatResult(
      driverId: driverId,
      isOnline: isOnline,
      isActive: isActive,
      serverTimeUtc: serverTimeUtc,
      nextHeartbeatAfterSeconds: nextHeartbeatAfterSeconds,
      activeSessionMissing: activeSessionMissing,
      responseSucceeded: responseSucceeded,
      message: message,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _readMessage(
    Map<String, dynamic> envelope,
    Map<String, dynamic> wrapped,
  ) {
    final outer = envelope['message'] ?? envelope['Message'];
    if (outer is String && outer.trim().isNotEmpty) {
      return outer.trim();
    }
    final inner = wrapped['message'] ?? wrapped['Message'];
    if (inner is String && inner.trim().isNotEmpty) {
      return inner.trim();
    }
    return null;
  }
}
