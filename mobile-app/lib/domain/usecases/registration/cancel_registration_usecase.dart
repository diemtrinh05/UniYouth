import '../../entities/registration/registration_status.dart';

class CancelRegistrationResult {
  const CancelRegistrationResult({
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

abstract class CancelRegistrationRepository {
  Future<CancelRegistrationResult> cancelRegistration({
    required int eventId,
    String? cancellationReason,
  });
}

class CancelRegistrationUseCase {
  const CancelRegistrationUseCase({
    required CancelRegistrationRepository repository,
  }) : _repository = repository;

  final CancelRegistrationRepository _repository;

  // Use case keeps cancel-registration flow out of UI and inside repository.
  Future<CancelRegistrationResult> call({
    required int eventId,
    String? cancellationReason,
  }) {
    return _repository.cancelRegistration(
      eventId: eventId,
      cancellationReason: cancellationReason,
    );
  }
}
