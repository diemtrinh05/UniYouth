abstract class ResetPasswordRepository {
  Future<String> resetPassword({
    required String verificationTicket,
    required String newPassword,
  });
}

class ResetPasswordUseCase {
  const ResetPasswordUseCase({
    required ResetPasswordRepository repository,
  }) : _repository = repository;

  final ResetPasswordRepository _repository;

  Future<String> call({
    required String verificationTicket,
    required String newPassword,
  }) {
    final normalizedVerificationTicket = verificationTicket.trim();

    if (normalizedVerificationTicket.isEmpty) {
      throw ArgumentError('verificationTicket is required for reset password.');
    }

    return _repository.resetPassword(
      verificationTicket: normalizedVerificationTicket,
      newPassword: newPassword,
    );
  }
}
