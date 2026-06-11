import '../../domain/entities/reset_password_result.dart';

class ResetPasswordResultModel {
  const ResetPasswordResultModel({
    required this.message,
  });

  final String message;

  factory ResetPasswordResultModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawMessage = json['message'] ?? json['Message'];
    return ResetPasswordResultModel(
      message:
          (rawMessage as String?)?.trim() ?? 'Password reset successfully.',
    );
  }

  ResetPasswordResult toEntity() {
    return ResetPasswordResult(message: message);
  }
}
