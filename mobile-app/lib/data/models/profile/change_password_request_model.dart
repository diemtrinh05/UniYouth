class ChangePasswordRequestModel {
  const ChangePasswordRequestModel({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmNewPassword': confirmNewPassword,
    };
  }
}
