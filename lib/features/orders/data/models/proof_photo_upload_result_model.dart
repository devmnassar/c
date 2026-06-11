import '../../domain/models/proof_photo_upload_result.dart';

class ProofPhotoUploadResultModel {
  const ProofPhotoUploadResultModel({
    required this.id,
    required this.orderId,
    required this.photoType,
    required this.filePath,
    required this.uploadedAt,
  });

  final int id;
  final int orderId;
  final int photoType;
  final String filePath;
  final DateTime uploadedAt;

  factory ProofPhotoUploadResultModel.fromJson(Map<String, dynamic> json) {
    return ProofPhotoUploadResultModel(
      id: _readInt(json['id']),
      orderId: _readInt(json['orderId']),
      photoType: _readInt(json['photoType']),
      filePath: (json['filePath'] as String?)?.trim() ?? '',
      uploadedAt: _readDateTime(json['uploadedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  ProofPhotoUploadResult toEntity() {
    return ProofPhotoUploadResult(
      id: id,
      orderId: orderId,
      photoType: _mapPhotoType(photoType),
      filePath: filePath,
      uploadedAt: uploadedAt,
    );
  }

  static ProofPhotoType _mapPhotoType(int value) {
    switch (value) {
      case 1:
        return ProofPhotoType.pickupProof;
      case 2:
        return ProofPhotoType.deliveryProof;
      case 3:
        return ProofPhotoType.attemptedDeliveryProof;
      case 4:
        return ProofPhotoType.laundryDropoffProof;
      default:
        return ProofPhotoType.deliveryProof;
    }
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
