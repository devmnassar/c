import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/send_register_otp_result.dart';
import '../repositories/sign_up_phone_repository.dart';

class SendRegisterOtpUseCase {
  const SendRegisterOtpUseCase(this._repository);

  final SignUpPhoneRepository _repository;

  Future<Either<ApiException, SendRegisterOtpResult>> call({
    required String phoneNumber,
  }) {
    return _repository.sendRegisterOtp(phoneNumber: phoneNumber);
  }
}
