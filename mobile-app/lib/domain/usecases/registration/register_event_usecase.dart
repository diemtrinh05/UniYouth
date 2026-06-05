import '../../entities/registration/registration_status.dart';

class RegisterEventResult {
  const RegisterEventResult({
    required this.registrationId,
    required this.eventId,
    required this.eventName,
    required this.userId,
    required this.userFullName,
    required this.registerTime,
    required this.status,
    required this.registrationStatus,
    required this.cancellationReason,
    required this.createdDate,
  });

  final int registrationId;
  final int eventId;
  final String? eventName;
  final int userId;
  final String? userFullName;
  final DateTime? registerTime;
  final String? status;
  final RegistrationStatus registrationStatus;
  final String? cancellationReason;
  final DateTime? createdDate;
}

abstract class RegisterEventRepository {
  Future<RegisterEventResult> registerEvent({required int eventId});
}

class RegisterEventUseCase {
  const RegisterEventUseCase({required RegisterEventRepository repository})
    : _repository = repository;

  final RegisterEventRepository _repository;

  // Use case to submit registration flow through repository, not directly from UI.
  Future<RegisterEventResult> call({required int eventId}) {
    return _repository.registerEvent(eventId: eventId);
  }
}
