class CheckInRequirements {
  const CheckInRequirements({
    required this.eventId,
    required this.eventName,
    required this.enableFaceVerification,
  });

  final int eventId;
  final String eventName;
  final bool enableFaceVerification;
}

abstract class CheckInRequirementsRepository {
  Future<CheckInRequirements> getCheckInRequirements({
    required String qrToken,
  });
}

class GetCheckInRequirementsUseCase {
  const GetCheckInRequirementsUseCase({
    required CheckInRequirementsRepository repository,
  }) : _repository = repository;

  final CheckInRequirementsRepository _repository;

  Future<CheckInRequirements> call({required String qrToken}) {
    return _repository.getCheckInRequirements(qrToken: qrToken);
  }
}
