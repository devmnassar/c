import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/register_auth_result.dart';
import '../entities/send_register_otp_result.dart';
import '../entities/verify_register_otp_result.dart';

abstract class SignUpPhoneRepository {
  Future<Either<ApiException, SendRegisterOtpResult>> sendRegisterOtp({
    required String phoneNumber,
  });

  Future<Either<ApiException, VerifyRegisterOtpResult>> verifyRegisterOtp({
    required String phoneNumber,
    required String code,
  });

  Future<Either<ApiException, RegisterAuthResult>> registerWithPhone({
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  });
}
