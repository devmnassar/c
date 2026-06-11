import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../../domain/entities/register_auth_result.dart';
import '../../domain/entities/send_register_otp_result.dart';
import '../../domain/entities/verify_register_otp_result.dart';
import '../../domain/repositories/sign_up_phone_repository.dart';
import '../datasources/sign_up_phone_remote_data_source.dart';

class SignUpPhoneRepositoryImpl implements SignUpPhoneRepository {
  const SignUpPhoneRepositoryImpl(this._remoteDataSource);

  final SignUpPhoneRemoteDataSource _remoteDataSource;

  @override
  Future<Either<ApiException, SendRegisterOtpResult>> sendRegisterOtp({
    required String phoneNumber,
  }) async {
    try {
      final model = await _remoteDataSource.sendRegisterOtp(
        phoneNumber: phoneNumber,
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, VerifyRegisterOtpResult>> verifyRegisterOtp({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final model = await _remoteDataSource.verifyRegisterOtp(
        phoneNumber: phoneNumber,
        code: code,
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, RegisterAuthResult>> registerWithPhone({
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final model = await _remoteDataSource.registerWithPhone(
        phoneNumber: phoneNumber,
        password: password,
        confirmPassword: confirmPassword,
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }
}
