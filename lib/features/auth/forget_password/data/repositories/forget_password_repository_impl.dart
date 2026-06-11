import 'package:dartz/dartz.dart';
import 'package:gaseel_courier/core/networking/api_exception.dart';

import '../../domain/entities/reset_password_result.dart';
import '../../domain/entities/send_reset_otp_result.dart';
import '../../domain/entities/verify_reset_otp_result.dart';
import '../../domain/repositories/forget_password_repository.dart';
import '../datasources/forget_password_remote_data_source.dart';

class ForgetPasswordRepositoryImpl implements ForgetPasswordRepository {
  const ForgetPasswordRepositoryImpl(this._remoteDataSource);

  final ForgetPasswordRemoteDataSource _remoteDataSource;

  @override
  Future<Either<ApiException, SendResetOtpResult>> sendResetOtp({
    required String phoneNumber,
  }) async {
    try {
      final model = await _remoteDataSource.sendResetOtp(
        phoneNumber: phoneNumber,
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, VerifyResetOtpResult>> verifyResetOtp({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final model = await _remoteDataSource.verifyResetOtp(
        phoneNumber: phoneNumber,
        code: code,
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }

  @override
  Future<Either<ApiException, ResetPasswordResult>> resetPassword({
    required String phoneNumber,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final model = await _remoteDataSource.resetPassword(
        phoneNumber: phoneNumber,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return right(model.toEntity());
    } on ApiException catch (error) {
      return left(error);
    } catch (_) {
      return left(
        const ApiException(message: 'Something went wrong, please try again.'),
      );
    }
  }
}
