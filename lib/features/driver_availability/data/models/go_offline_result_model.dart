import '../../domain/entities/go_offline_result.dart';

class GoOfflineResultModel {
  const GoOfflineResultModel({
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

  factory GoOfflineResultModel.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    return GoOfflineResultModel(
      driverId: _readInt(json['driverId']),
      isOnline: json['isOnline'] == true,
      onlineSessionId: (json['onlineSessionId'] as String?)?.trim() ?? '',
      offlineAtUtc: DateTime.tryParse(
        (json['offlineAtUtc'] as String?)?.trim() ?? '',
      ),
      message: message,
    );
  }

  GoOfflineResult toEntity() {
    return GoOfflineResult(
      driverId: driverId,
      isOnline: isOnline,
      onlineSessionId: onlineSessionId,
      offlineAtUtc: offlineAtUtc,
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
