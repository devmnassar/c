import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gaseel_courier/features/orders/domain/models/proof_photo_upload_result.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/update_rider_status_use_case.dart';
import 'package:gaseel_courier/features/orders/domain/usecases/upload_proof_photo_use_case.dart';

part 'delivery_completion_state.dart';

const Object _unset = Object();

class DeliveryCompletionCubit extends Cubit<DeliveryCompletionState> {
  DeliveryCompletionCubit({
    required UploadProofPhotoUseCase uploadProofPhotoUseCase,
    required UpdateRiderStatusUseCase updateRiderStatusUseCase,
  })  : _uploadProofPhotoUseCase = uploadProofPhotoUseCase,
        _updateRiderStatusUseCase = updateRiderStatusUseCase,
        super(const DeliveryCompletionState());

  final UploadProofPhotoUseCase _uploadProofPhotoUseCase;
  final UpdateRiderStatusUseCase _updateRiderStatusUseCase;

  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint(
      '================ DELIVERY COMPLETION CUBIT ================',
    );
    debugPrint('[DELIVERY COMPLETION CUBIT] $message');
  }

  Future<void> deliverOrder({
    required String orderId,
    required String proofPhotoPath,
  }) {
    return _completeOrder(
      orderId: orderId,
      proofPhotoPath: proofPhotoPath,
      photoType: ProofPhotoType.deliveryProof,
      riderStatus: 6,
      action: DeliveryCompletionAction.deliver,
      actionName: 'deliverOrder',
      successMessage: 'Order delivered successfully.',
    );
  }

  Future<void> attemptDelivery({
    required String orderId,
    required String proofPhotoPath,
  }) {
    return _completeOrder(
      orderId: orderId,
      proofPhotoPath: proofPhotoPath,
      photoType: ProofPhotoType.attemptedDeliveryProof,
      riderStatus: 7,
      action: DeliveryCompletionAction.attemptDelivery,
      actionName: 'attemptDelivery',
      successMessage: 'Attempted delivery marked successfully.',
    );
  }

  Future<void> _completeOrder({
    required String orderId,
    required String proofPhotoPath,
    required ProofPhotoType photoType,
    required int riderStatus,
    required DeliveryCompletionAction action,
    required String actionName,
    required String successMessage,
  }) async {
    final file = File(proofPhotoPath);
    final exists = await file.exists();
    final fileSizeBytes = exists ? await file.length() : 0;
    final extension = proofPhotoPath.split('.').last.toLowerCase();

    _log(
      '$actionName started. '
      'orderId=$orderId, proofPhotoPath=$proofPhotoPath, '
      'exists=$exists, sizeBytes=$fileSizeBytes, extension=$extension, '
      'photoType=${photoType.value}, riderStatus=$riderStatus',
    );

    if (!exists) {
      const message = 'Selected proof photo could not be found.';
      _log('$actionName blocked: $message');
      emit(
        state.copyWith(
          status: DeliveryCompletionStatus.failure,
          currentAction: action,
          errorMessage: message,
          successMessage: null,
        ),
      );
      return;
    }

    if (fileSizeBytes > 10 * 1024 * 1024) {
      const message = 'File exceeds the 10 MB limit.';
      _log('$actionName blocked: $message');
      emit(
        state.copyWith(
          status: DeliveryCompletionStatus.failure,
          currentAction: action,
          errorMessage: message,
          successMessage: null,
        ),
      );
      return;
    }

    if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
      const message = 'Only jpg and png files are allowed.';
      _log('$actionName blocked: $message');
      emit(
        state.copyWith(
          status: DeliveryCompletionStatus.failure,
          currentAction: action,
          errorMessage: message,
          successMessage: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: DeliveryCompletionStatus.submitting,
        currentAction: action,
        errorMessage: null,
        successMessage: null,
      ),
    );
    _log('State -> submitting');

    final position = await _tryGetCurrentPosition();
    _log(
      'GPS snapshot collected. latitude=${position?.latitude}, '
      'longitude=${position?.longitude}',
    );

    final uploadResult = await _uploadProofPhotoUseCase(
      orderId: orderId,
      filePath: proofPhotoPath,
      photoType: photoType,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );

    final uploaded = await uploadResult.fold(
      (error) async {
        _log('Proof photo upload failed: ${error.message}');
        emit(
          state.copyWith(
            status: DeliveryCompletionStatus.failure,
            currentAction: action,
            errorMessage: error.message,
            successMessage: null,
          ),
        );
        return false;
      },
      (result) async {
        _log(
          'Proof photo upload succeeded. uploadId=${result.id}, '
          'filePath=${result.filePath}, uploadedAt=${result.uploadedAt.toIso8601String()}',
        );
        return true;
      },
    );

    if (!uploaded) {
      return;
    }

    _log(
      'Calling gated delivery-status endpoint with status=$riderStatus '
      'after proof photo upload',
    );
    final updateResult = await _updateRiderStatusUseCase(
      orderId: orderId,
      status: riderStatus,
    );

    updateResult.fold(
      (error) {
        _log(
          '$actionName delivery-status update failed: ${error.message}',
        );
        emit(
          state.copyWith(
            status: DeliveryCompletionStatus.failure,
            currentAction: action,
            errorMessage: error.message,
            successMessage: null,
          ),
        );
      },
      (_) {
        _log(
          '$actionName delivery-status update succeeded. State -> success',
        );
        emit(
          state.copyWith(
            status: DeliveryCompletionStatus.success,
            currentAction: action,
            errorMessage: null,
            successMessage: successMessage,
          ),
        );
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
    _log('State reset to initial');
    emit(const DeliveryCompletionState());
  }
}
