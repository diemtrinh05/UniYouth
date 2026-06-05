class VerifyResetOtpResponseModel {
  const VerifyResetOtpResponseModel({
    this.message,
    required this.verificationTicket,
    required this.expiresAt,
  });

  final String? message;
  final String verificationTicket;
  final DateTime expiresAt;

  factory VerifyResetOtpResponseModel.fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final message = json['message']?.toString().trim();
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid verify reset OTP response payload.');
    }

    final typedData = data.map((key, value) => MapEntry(key.toString(), value));
    final verificationTicket =
        typedData['verificationTicket']?.toString() ?? '';
    final expiresAtRaw = typedData['expiresAt']?.toString() ?? '';
    final expiresAt = DateTime.tryParse(expiresAtRaw);

    if (verificationTicket.trim().isEmpty || expiresAt == null) {
      throw const FormatException(
        'Missing verificationTicket or expiresAt in verify reset OTP response.',
      );
    }

    return VerifyResetOtpResponseModel(
      message: message == null || message.isEmpty ? null : message,
      verificationTicket: verificationTicket,
      expiresAt: expiresAt,
    );
  }
}
