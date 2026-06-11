import '../../domain/entities/go_online_result.dart';

class GoOnlineResultModel {
  const GoOnlineResultModel({
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

  factory GoOnlineResultModel.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    return GoOnlineResultModel(
      driverId: _readInt(json['driverId']),
      isOnline: json['isOnline'] == true,
      onlineSessionId: (json['onlineSessionId'] as String?)?.trim() ?? '',
      serverTimeUtc: DateTime.tryParse(
            (json['serverTimeUtc'] as String?)?.trim() ?? '',
          ) ??
          DateTime.now().toUtc(),
      nextRecommendedLocationUpdateSeconds: _readInt(
        json['nextRecommendedLocationUpdateSeconds'],
      ),
      message: message,
    );
  }

  GoOnlineResult toEntity() {
    return GoOnlineResult(
      driverId: driverId,
      isOnline: isOnline,
      onlineSessionId: onlineSessionId,
      serverTimeUtc: serverTimeUtc,
      nextRecommendedLocationUpdateSeconds:
          nextRecommendedLocationUpdateSeconds,
      message: message,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
