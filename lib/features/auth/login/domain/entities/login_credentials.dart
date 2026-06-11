class LoginCredentials {
  const LoginCredentials({
    required this.phoneNumber,
    required this.password,
  });

  final String phoneNumber;
  final String password;

  String get sanitizedPhoneNumber => phoneNumber.replaceAll(RegExp(r'\s+'), '');
}
