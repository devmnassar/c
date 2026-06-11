import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../entities/register_auth_result.dart';
import '../repositories/sign_up_phone_repository.dart';

class RegisterWithPhoneUseCase {
  const RegisterWithPhoneUseCase(this._repository);

  final SignUpPhoneRepository _repository;

  Future<Either<ApiException, RegisterAuthResult>> call({
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) {
    return _repository.registerWithPhone(
      phoneNumber: phoneNumber,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
