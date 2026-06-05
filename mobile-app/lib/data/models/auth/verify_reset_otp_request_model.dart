class VerifyResetOtpRequestModel {
  const VerifyResetOtpRequestModel({
    required this.account,
    required this.otpCode,
  });

  final String account;
  final String otpCode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'account': account,
      'otpCode': otpCode,
    };
  }
}
