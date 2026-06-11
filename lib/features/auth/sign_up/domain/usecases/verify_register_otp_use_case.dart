import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/verify_register_otp_result.dart';
import '../repositories/sign_up_phone_repository.dart';

class VerifyRegisterOtpUseCase {
  const VerifyRegisterOtpUseCase(this._repository);

  final SignUpPhoneRepository _repository;

  Future<Either<ApiException, VerifyRegisterOtpResult>> call({
    required String phoneNumber,
    required String code,
  }) {
    return _repository.verifyRegisterOtp(
      phoneNumber: phoneNumber,
      code: code,
    );
  }
}
