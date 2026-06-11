enum ProofPhotoType {
  pickupProof(1),
  deliveryProof(2),
  attemptedDeliveryProof(3),
  laundryDropoffProof(4);

  const ProofPhotoType(this.value);

  final int value;
}

class ProofPhotoUploadResult {
  const ProofPhotoUploadResult({
    required this.id,
    required this.orderId,
    required this.photoType,
    required this.filePath,
    required this.uploadedAt,
  });

  final int id;
  final int orderId;
  final ProofPhotoType photoType;
  final String filePath;
  final DateTime uploadedAt;
}
