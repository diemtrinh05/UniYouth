class VerifyResetOtpResult {
  const VerifyResetOtpResult({
    this.message,
    required this.verificationTicket,
    required this.expiresAt,
  });

  final String? message;
  final String verificationTicket;
  final DateTime expiresAt;
}

abstract class VerifyResetOtpRepository {
  Future<VerifyResetOtpResult> verifyResetOtp({
    required String account,
    required String otpCode,
  });
}

class VerifyResetOtpUseCase {
  const VerifyResetOtpUseCase({
    required VerifyResetOtpRepository repository,
  }) : _repository = repository;

  final VerifyResetOtpRepository _repository;

  Future<VerifyResetOtpResult> call({
    required String account,
    required String otpCode,
  }) {
    return _repository.verifyResetOtp(
      account: account,
      otpCode: otpCode,
    );
  }
}
