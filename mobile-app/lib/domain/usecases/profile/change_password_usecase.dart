class ChangePasswordInput {
  const ChangePasswordInput({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;
}

class ChangePasswordResult {
  const ChangePasswordResult({
    required this.success,
    required this.message,
    required this.additionalInfo,
  });

  final bool success;
  final String? message;
  final String? additionalInfo;
}

abstract class ChangePasswordRepository {
  Future<ChangePasswordResult> changePassword({
    required ChangePasswordInput input,
  });
}

class ChangePasswordUseCase {
  const ChangePasswordUseCase({required ChangePasswordRepository repository})
    : _repository = repository;

  final ChangePasswordRepository _repository;

  // Submit change password request to backend /api/Users/change-password.
  Future<ChangePasswordResult> call({required ChangePasswordInput input}) {
    return _repository.changePassword(input: input);
  }
}
