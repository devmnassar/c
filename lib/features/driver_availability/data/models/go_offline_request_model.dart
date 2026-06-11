import '../../domain/entities/go_offline_request.dart';

class GoOfflineRequestModel {
  const GoOfflineRequestModel({
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

  factory GoOfflineRequestModel.fromEntity(GoOfflineRequest entity) {
    return GoOfflineRequestModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      deviceId: entity.deviceId,
      clientTimestampUtc: entity.clientTimestampUtc,
      reason: entity.reason,
    );
  }

  Map<String, dynamic> toJson() {
    final hasCoordinates = latitude != null && longitude != null;
    return <String, dynamic>{
      if (hasCoordinates) 'latitude': latitude,
      if (hasCoordinates) 'longitude': longitude,
      if (hasCoordinates && accuracy != null) 'accuracy': accuracy,
      if (deviceId != null && deviceId!.trim().isNotEmpty) 'deviceId': deviceId,
      'clientTimestampUtc': clientTimestampUtc.toUtc().toIso8601String(),
      'reason': reason,
    };
  }

  String toDebugLines() {
    final buffer = StringBuffer()
      ..writeln('================ GO OFFLINE BODY ================')
      ..writeln('latitude: ${latitude ?? '(null)'}')
      ..writeln('longitude: ${longitude ?? '(null)'}')
      ..writeln('accuracy: ${accuracy ?? '(null)'}')
      ..writeln('deviceId: ${deviceId ?? '(null)'}')
      ..writeln(
        'clientTimestampUtc: ${clientTimestampUtc.toUtc().toIso8601String()}',
      )
      ..writeln('reason: $reason')
      ..write('=================================================');
    return buffer.toString();
  }
}
