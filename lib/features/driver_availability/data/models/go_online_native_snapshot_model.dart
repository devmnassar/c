class GoOnlineNativeSnapshotModel {
  const GoOnlineNativeSnapshotModel({
    required this.deviceId,
    required this.deviceModel,
    required this.batteryLevel,
    required this.networkType,
  });

  final String deviceId;
  final String deviceModel;
  final int batteryLevel;
  final String networkType;

  factory GoOnlineNativeSnapshotModel.fromMap(Map<Object?, Object?> map) {
    final rawBattery = map['batteryLevel'];
    return GoOnlineNativeSnapshotModel(
      deviceId: (map['deviceId'] as String?)?.trim() ?? '',
      deviceModel: (map['deviceModel'] as String?)?.trim() ?? '',
      batteryLevel: rawBattery is int
          ? rawBattery
          : rawBattery is num
              ? rawBattery.toInt()
              : int.tryParse('${map['batteryLevel']}') ?? 0,
      networkType: (map['networkType'] as String?)?.trim() ?? '',
    );
  }
}
