class FaceProfileReauthOtpResultModel {
  const FaceProfileReauthOtpResultModel({
    required this.message,
  });

  final String? message;

  factory FaceProfileReauthOtpResultModel.fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return FaceProfileReauthOtpResultModel(
        message: (json['message'] as String?)?.trim(),
      );
    }

    return FaceProfileReauthOtpResultModel(
      message: (json['message'] as String?)?.trim(),
    );
  }
}
