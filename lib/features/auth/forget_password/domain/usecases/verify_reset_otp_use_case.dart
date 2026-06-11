import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/verify_reset_otp_result.dart';
import '../repositories/forget_password_repository.dart';

class VerifyResetOtpUseCase {
  const VerifyResetOtpUseCase(this._repository);

  final ForgetPasswordRepository _repository;

  Future<Either<ApiException, VerifyResetOtpResult>> call({
    required String phoneNumber,
    required String code,
  }) {
    return _repository.verifyResetOtp(phoneNumber: phoneNumber, code: code);
  }
}
