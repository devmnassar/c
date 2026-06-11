part of 'otp_cubit.dart';

enum OtpStatus { initial, loading, success, failure }

class OtpState {
  const OtpState({
    this.status = OtpStatus.initial,
    this.errorMessage,
    this.infoMessage,
    this.uiEventId = 0,
  });

  final OtpStatus status;
  final String? errorMessage;
  final String? infoMessage;
  final int uiEventId;

  bool get isLoading => status == OtpStatus.loading;

  OtpState copyWith({
    OtpStatus? status,
    String? errorMessage,
    String? infoMessage,
    int? uiEventId,
  }) {
    return OtpState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
      uiEventId: uiEventId ?? this.uiEventId,
    );
  }
}
