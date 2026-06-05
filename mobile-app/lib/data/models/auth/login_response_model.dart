class LoginResponseModel {
  const LoginResponseModel({
    required this.token,
    required this.expiresAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  final String token;
  final DateTime expiresAt;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;

  factory LoginResponseModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid login response payload.');
    }

    final typedData = data.map((key, value) => MapEntry(key.toString(), value));
    final token = typedData['token']?.toString() ?? '';
    final expiresAtRaw = typedData['expiresAt']?.toString() ?? '';
    final refreshTokenRaw = typedData['refreshToken']?.toString();
    final refreshTokenExpiresAtRaw =
        typedData['refreshTokenExpiresAt']?.toString();
    final expiresAt = DateTime.tryParse(expiresAtRaw);
    final refreshTokenExpiresAt =
        DateTime.tryParse(refreshTokenExpiresAtRaw ?? '');

    if (token.trim().isEmpty || expiresAt == null) {
      throw const FormatException('Missing token or expiresAt in login response.');
    }

    return LoginResponseModel(
      token: token,
      expiresAt: expiresAt,
      refreshToken: refreshTokenRaw?.trim().isEmpty ?? true
          ? null
          : refreshTokenRaw?.trim(),
      refreshTokenExpiresAt: refreshTokenExpiresAt,
    );
  }
}
