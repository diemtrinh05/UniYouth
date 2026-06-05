class ForgotPasswordRequestModel {
  const ForgotPasswordRequestModel({
    required this.account,
  });

  final String account;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'account': account,
    };
  }
}
