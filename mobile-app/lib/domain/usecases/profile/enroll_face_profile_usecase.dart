class EnrollFaceProfileInput {
  const EnrollFaceProfileInput({
    required this.imageBytes,
    required this.imageMimeType,
    this.reauthOtpCode,
  });

  final List<int> imageBytes;
  final String imageMimeType;
  final String? reauthOtpCode;
}

class EnrollFaceProfileResult {
  const EnrollFaceProfileResult({
    required this.imageUrl,
    required this.message,
    required this.qualityScore,
  });

  final String? imageUrl;
  final String? message;
  final double? qualityScore;
}

abstract class EnrollFaceProfileRepository {
  Future<EnrollFaceProfileResult> enrollFaceProfile({
    required EnrollFaceProfileInput input,
  });
}

class EnrollFaceProfileUseCase {
  const EnrollFaceProfileUseCase({
    required EnrollFaceProfileRepository repository,
  }) : _repository = repository;

  final EnrollFaceProfileRepository _repository;

  Future<EnrollFaceProfileResult> call({
    required EnrollFaceProfileInput input,
  }) {
    return _repository.enrollFaceProfile(input: input);
  }
}
