import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gaseel_courier/features/orders/domain/models/proof_photo_upload_result.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_pickup_status_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/upload_proof_photo_use_case.dart';

part 'pickup_status_state.dart';

const Object _pickupUnset = Object();

class PickupStatusCubit extends Cubit<PickupStatusState> {
  PickupStatusCubit({
    required UpdatePickupStatusUseCase updatePickupStatusUseCase,
    required UploadProofPhotoUseCase uploadProofPhotoUseCase,
  })  : _updatePickupStatusUseCase = updatePickupStatusUseCase,
        _uploadProofPhotoUseCase = uploadProofPhotoUseCase,
        super(const PickupStatusState());

  final UpdatePickupStatusUseCase _updatePickupStatusUseCase;
  final UploadProofPhotoUseCase _uploadProofPhotoUseCase;

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('================ PICKUP STATUS CUBIT ================');
    debugPrint('[PICKUP STATUS CUBIT] $message');
  }

  Future<bool> submitStatus({
    required String orderId,
    required int status,
    String? proofPhotoPath,
    ProofPhotoType? proofPhotoType,
  }) async {
    _log(
      'submitStatus started. orderId=$orderId status=$status '
      'proofPhotoPath=$proofPhotoPath proofPhotoType=$proofPhotoType',
    );
    emit(
      state.copyWith(
        status: PickupStatusSubmissionStatus.submitting,
        errorMessage: null,
        lastSubmittedStatus: status,
      ),
    );

    if (proofPhotoPath != null &&
        proofPhotoPath.trim().isNotEmpty &&
        proofPhotoType != null) {
      final file = File(proofPhotoPath);
      final exists = await file.exists();
      if (!exists) {
        const message = 'Selected proof photo could not be found.';
        emit(
          state.copyWith(
            status: PickupStatusSubmissionStatus.failure,
            errorMessage: message,
          ),
        );
        return false;
      }

      final position = await _tryGetCurrentPosition();
      final uploadResult = await _uploadProofPhotoUseCase(
        orderId: orderId,
        filePath: proofPhotoPath,
        photoType: proofPhotoType,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      final uploaded = uploadResult.fold(
        (error) {
          emit(
            state.copyWith(
              status: PickupStatusSubmissionStatus.failure,
              errorMessage: error.message,
            ),
          );
          return false;
        },
        (_) => true,
      );

      if (!uploaded) {
        return false;
      }
    }

    final result = await _updatePickupStatusUseCase(
      orderId: orderId,
      status: status,
    );

    return result.fold(
      (error) {
        emit(
          state.copyWith(
            status: PickupStatusSubmissionStatus.failure,
            errorMessage: error.message,
          ),
        );
        return false;
      },
      (_) {
        emit(
          state.copyWith(
            status: PickupStatusSubmissionStatus.success,
            errorMessage: null,
            lastSubmittedStatus: status,
          ),
        );
        return true;
      },
    );
  }

  Future<Position?> _tryGetCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (error) {
      _log('GPS capture skipped: $error');
      return null;
    }
  }

  void reset() {
    emit(const PickupStatusState());
  }
}
