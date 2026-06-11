import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/reset_password_result.dart';
import '../entities/send_reset_otp_result.dart';
import '../entities/verify_reset_otp_result.dart';

abstract class ForgetPasswordRepository {
  Future<Either<ApiException, SendResetOtpResult>> sendResetOtp({
    required String phoneNumber,
  });

  Future<Either<ApiException, VerifyResetOtpResult>> verifyResetOtp({
    required String phoneNumber,
    required String code,
  });

  Future<Either<ApiException, ResetPasswordResult>> resetPassword({
    required String phoneNumber,
    required String newPassword,
    required String confirmPassword,
  });
}
