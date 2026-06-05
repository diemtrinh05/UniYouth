class ResetPasswordRequestModel {
  const ResetPasswordRequestModel({
    required this.verificationTicket,
    required this.newPassword,
  }) : assert(
         verificationTicket != '',
         'verificationTicket is required.',
       );

  final String verificationTicket;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'verificationTicket': verificationTicket.trim(),
      'newPassword': newPassword,
    };
  }
}
