class AuthResult {
  final String token;
  final String name;
  final String expiresIn;

  AuthResult({
    required this.token,
    required this.name,
    required this.expiresIn,
  });
}
