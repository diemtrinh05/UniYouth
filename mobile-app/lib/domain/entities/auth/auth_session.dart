class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  final String token;
  final DateTime expiresAt;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;
}
