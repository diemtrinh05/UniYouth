class RequestFaceProfileReauthOtpResult {
  const RequestFaceProfileReauthOtpResult({
    required this.message,
  });

  final String? message;
}

abstract class RequestFaceProfileReauthOtpRepository {
  Future<RequestFaceProfileReauthOtpResult> requestFaceProfileReauthOtp();
}

class RequestFaceProfileReauthOtpUseCase {
  const RequestFaceProfileReauthOtpUseCase({
    required RequestFaceProfileReauthOtpRepository repository,
  }) : _repository = repository;

  final RequestFaceProfileReauthOtpRepository _repository;

  Future<RequestFaceProfileReauthOtpResult> call() {
    return _repository.requestFaceProfileReauthOtp();
  }
}
