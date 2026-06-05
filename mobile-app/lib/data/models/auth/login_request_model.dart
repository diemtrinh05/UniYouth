class LoginRequestModel {
  const LoginRequestModel({
    required this.code,
    required this.password,
  });

  final String code;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'password': password,
    };
  }
}

