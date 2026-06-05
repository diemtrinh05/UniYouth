class MyPointsSummary {
  const MyPointsSummary({
    required this.totalPoints,
    required this.eventsParticipated,
    required this.validAttendances,
    required this.fullName,
    required this.code,
  });

  final int totalPoints;
  final int eventsParticipated;
  final int validAttendances;
  final String? fullName;
  final String? code;
}

abstract class GetMyPointsRepository {
  Future<MyPointsSummary> getMyPoints();
}

class GetMyPointsUseCase {
  const GetMyPointsUseCase({required GetMyPointsRepository repository})
    : _repository = repository;

  final GetMyPointsRepository _repository;

  // Load current user points summary directly from backend.
  Future<MyPointsSummary> call() {
    return _repository.getMyPoints();
  }
}

