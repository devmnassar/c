import 'dart:io';

import 'package:gaseel_courier/features/orders/domain/models/proof_photo_upload_result.dart';

/// Creates a temporary proof photo file for [PickupStatusCubit] tests.
Future<String> createTempProofPhoto({
  String extension = 'jpg',
  int byteLength = 128,
}) async {
  final directory = Directory.systemTemp.createTempSync('trip_cubit_test');
  final file = File('${directory.path}/proof.$extension');
  await file.writeAsBytes(List.filled(byteLength, 0));
  return file.path;
}

ProofPhotoUploadResult samplePickupUploadResult({
  String orderId = '42',
  String filePath = '/tmp/proof.jpg',
}) {
  return ProofPhotoUploadResult(
    id: 1,
    orderId: int.parse(orderId),
    photoType: ProofPhotoType.pickupProof,
    filePath: filePath,
    uploadedAt: DateTime.utc(2026, 1, 15, 12, 0),
  );
}
