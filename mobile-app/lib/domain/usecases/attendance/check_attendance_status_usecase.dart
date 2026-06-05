class AttendanceCheckStatus {
  const AttendanceCheckStatus({
    required this.eventId,
    required this.hasCheckedIn,
    required this.isValid,
    required this.invalidReason,
  });

  final int eventId;
  final bool hasCheckedIn;
  final bool? isValid;
  final String? invalidReason;
}

abstract class CheckAttendanceStatusRepository {
  Future<AttendanceCheckStatus> getAttendanceCheckStatus({
    required int eventId,
  });
}

class CheckAttendanceStatusUseCase {
  const CheckAttendanceStatusUseCase({
    required CheckAttendanceStatusRepository repository,
  }) : _repository = repository;

  final CheckAttendanceStatusRepository _repository;

  // Load check-in state of current user for one event before opening scan flow.
  Future<AttendanceCheckStatus> call({required int eventId}) {
    return _repository.getAttendanceCheckStatus(eventId: eventId);
  }
}
