import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/reset_password_result.dart';
import '../repositories/forget_password_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final ForgetPasswordRepository _repository;

  Future<Either<ApiException, ResetPasswordResult>> call({
    required String phoneNumber,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _repository.resetPassword(
      phoneNumber: phoneNumber,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
