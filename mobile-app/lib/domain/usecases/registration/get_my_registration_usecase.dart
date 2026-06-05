import '../../entities/registration/registration_status.dart';

class MyRegistrationInfo {
  const MyRegistrationInfo({
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

class MyRegistrationState {
  const MyRegistrationState._({
    required this.isRegistered,
    required this.registration,
  });

  const MyRegistrationState.registered(MyRegistrationInfo registration)
    : this._(isRegistered: true, registration: registration);

  const MyRegistrationState.notRegistered()
    : this._(isRegistered: false, registration: null);

  final bool isRegistered;
  final MyRegistrationInfo? registration;
}

abstract class MyRegistrationRepository {
  Future<MyRegistrationState> getMyRegistration({required int eventId});
}

class GetMyRegistrationUseCase {
  const GetMyRegistrationUseCase({required MyRegistrationRepository repository})
    : _repository = repository;

  final MyRegistrationRepository _repository;

  // Use case trả về trạng thái đăng ký của user hiện tại theo eventId.
  Future<MyRegistrationState> call({required int eventId}) {
    return _repository.getMyRegistration(eventId: eventId);
  }
}
