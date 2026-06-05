import '../../../../../../domain/usecases/attendance/check_attendance_status_usecase.dart';
import '../../../../../../domain/usecases/events/get_event_detail_usecase.dart';
import '../../../../../../domain/usecases/registration/get_my_registration_usecase.dart';

class EventDetailState {
  const EventDetailState({
    this.isLoading = true,
    this.errorMessage,
    this.eventDetail,
    this.isRegistrationLoading = true,
    this.registrationErrorMessage,
    this.registrationState,
    this.isRegistering = false,
    this.registerCooldownSeconds = 0,
    this.isCancelling = false,
    this.isAttendanceStatusLoading = true,
    this.attendanceStatusErrorMessage,
    this.attendanceStatus,
    this.isOpeningCheckIn = false,
    this.feedbackMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final EventDetail? eventDetail;

  final bool isRegistrationLoading;
  final String? registrationErrorMessage;
  final MyRegistrationState? registrationState;
  final bool isRegistering;
  final int registerCooldownSeconds;
  final bool isCancelling;

  final bool isAttendanceStatusLoading;
  final String? attendanceStatusErrorMessage;
  final AttendanceCheckStatus? attendanceStatus;
  final bool isOpeningCheckIn;

  final String? feedbackMessage;

  bool get isRegisterRateLimited => registerCooldownSeconds > 0;

  EventDetailState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    EventDetail? eventDetail,
    bool clearEventDetail = false,
    bool? isRegistrationLoading,
    String? registrationErrorMessage,
    bool clearRegistrationErrorMessage = false,
    MyRegistrationState? registrationState,
    bool clearRegistrationState = false,
    bool? isRegistering,
    int? registerCooldownSeconds,
    bool? isCancelling,
    bool? isAttendanceStatusLoading,
    String? attendanceStatusErrorMessage,
    bool clearAttendanceStatusErrorMessage = false,
    AttendanceCheckStatus? attendanceStatus,
    bool clearAttendanceStatus = false,
    bool? isOpeningCheckIn,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return EventDetailState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      eventDetail: clearEventDetail ? null : (eventDetail ?? this.eventDetail),
      isRegistrationLoading: isRegistrationLoading ?? this.isRegistrationLoading,
      registrationErrorMessage: clearRegistrationErrorMessage
          ? null
          : (registrationErrorMessage ?? this.registrationErrorMessage),
      registrationState: clearRegistrationState
          ? null
          : (registrationState ?? this.registrationState),
      isRegistering: isRegistering ?? this.isRegistering,
      registerCooldownSeconds:
          registerCooldownSeconds ?? this.registerCooldownSeconds,
      isCancelling: isCancelling ?? this.isCancelling,
      isAttendanceStatusLoading:
          isAttendanceStatusLoading ?? this.isAttendanceStatusLoading,
      attendanceStatusErrorMessage: clearAttendanceStatusErrorMessage
          ? null
          : (attendanceStatusErrorMessage ?? this.attendanceStatusErrorMessage),
      attendanceStatus: clearAttendanceStatus
          ? null
          : (attendanceStatus ?? this.attendanceStatus),
      isOpeningCheckIn: isOpeningCheckIn ?? this.isOpeningCheckIn,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }
}
