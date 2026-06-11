import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../models/proof_photo_upload_result.dart';
import '../repositories/mobile_orders_repository.dart';

class UploadProofPhotoUseCase {
  const UploadProofPhotoUseCase(this._repository);

  final MobileOrdersRepository _repository;

  Future<Either<ApiException, ProofPhotoUploadResult>> call({
    required String orderId,
    required String filePath,
    required ProofPhotoType photoType,
    double? latitude,
    double? longitude,
  }) {
    return _repository.uploadProofPhoto(
      orderId: orderId,
      filePath: filePath,
      photoType: photoType,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
