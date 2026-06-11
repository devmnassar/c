import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/send_reset_otp_result.dart';
import '../repositories/forget_password_repository.dart';

class SendResetOtpUseCase {
  const SendResetOtpUseCase(this._repository);

  final ForgetPasswordRepository _repository;

  Future<Either<ApiException, SendResetOtpResult>> call({
    required String phoneNumber,
  }) {
    return _repository.sendResetOtp(phoneNumber: phoneNumber);
  }
}
