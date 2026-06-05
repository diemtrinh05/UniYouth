import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/domain/entities/registration/registration_status.dart';
import 'package:uniyouth_app/domain/usecases/attendance/check_attendance_status_usecase.dart';
import 'package:uniyouth_app/domain/usecases/events/get_event_detail_usecase.dart';
import 'package:uniyouth_app/domain/usecases/registration/cancel_registration_usecase.dart';
import 'package:uniyouth_app/domain/usecases/registration/get_my_registration_usecase.dart';
import 'package:uniyouth_app/domain/usecases/registration/register_event_usecase.dart';
import 'package:uniyouth_app/presentation/features/events/event_detail/state/event_detail_notifier.dart';

void main() {
  group('EventDetailNotifier', () {
    test(
      'syncInitial loads detail, registration, and attendance status',
      () async {
        final eventDetailRepository = _FakeEventDetailRepository();
        final registrationRepository = _FakeMyRegistrationRepository();
        final attendanceRepository = _FakeAttendanceStatusRepository();

        final notifier = EventDetailNotifier(
          eventId: 101,
          getEventDetailUseCase: GetEventDetailUseCase(
            repository: eventDetailRepository,
          ),
          getMyRegistrationUseCase: GetMyRegistrationUseCase(
            repository: registrationRepository,
          ),
          registerEventUseCase: RegisterEventUseCase(
            repository: _FakeRegisterEventRepository(),
          ),
          cancelRegistrationUseCase: CancelRegistrationUseCase(
            repository: _FakeCancelRegistrationRepository(),
          ),
          checkAttendanceStatusUseCase: CheckAttendanceStatusUseCase(
            repository: attendanceRepository,
          ),
          notifyEventChanged: (_) {},
        );
        addTearDown(notifier.dispose);

        await notifier.syncInitial();

        expect(eventDetailRepository.callCount, 1);
        expect(registrationRepository.callCount, 1);
        expect(attendanceRepository.callCount, 1);
        expect(notifier.state.eventDetail?.eventId, 101);
        expect(notifier.state.registrationState?.isRegistered, isFalse);
        expect(notifier.state.attendanceStatus?.hasCheckedIn, isFalse);
        expect(notifier.state.attendanceStatus?.isValid, isNull);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.isRegistrationLoading, isFalse);
        expect(notifier.state.isAttendanceStatusLoading, isFalse);
      },
    );

    test('syncInitial keeps invalid attendance status details', () async {
      final notifier = EventDetailNotifier(
        eventId: 101,
        getEventDetailUseCase: GetEventDetailUseCase(
          repository: _FakeEventDetailRepository(),
        ),
        getMyRegistrationUseCase: GetMyRegistrationUseCase(
          repository: _FakeMyRegistrationRepository(),
        ),
        registerEventUseCase: RegisterEventUseCase(
          repository: _FakeRegisterEventRepository(),
        ),
        cancelRegistrationUseCase: CancelRegistrationUseCase(
          repository: _FakeCancelRegistrationRepository(),
        ),
        checkAttendanceStatusUseCase: CheckAttendanceStatusUseCase(
          repository: _FakeAttendanceStatusRepository(
            state: const AttendanceCheckStatus(
              eventId: 101,
              hasCheckedIn: true,
              isValid: false,
              invalidReason: 'Khoảng cách quá xa so với bán kính cho phép.',
            ),
          ),
        ),
        notifyEventChanged: (_) {},
      );
      addTearDown(notifier.dispose);

      await notifier.syncInitial();

      expect(notifier.state.attendanceStatus?.hasCheckedIn, isTrue);
      expect(notifier.state.attendanceStatus?.isValid, isFalse);
      expect(
        notifier.state.attendanceStatus?.invalidReason,
        'Khoảng cách quá xa so với bán kính cho phép.',
      );
    });

    test(
      'registerForEvent notifies refresh signal and updates feedback',
      () async {
        final notifiedIds = <int>[];
        final registerRepository = _FakeRegisterEventRepository()
          ..onRegisterEvent = ({required eventId}) async {
            return _registerResult(eventId: eventId);
          };
        final notifier = EventDetailNotifier(
          eventId: 101,
          getEventDetailUseCase: GetEventDetailUseCase(
            repository: _FakeEventDetailRepository(),
          ),
          getMyRegistrationUseCase: GetMyRegistrationUseCase(
            repository: _FakeMyRegistrationRepository(
              state: MyRegistrationState.registered(
                const MyRegistrationInfo(
                  registrationId: 1,
                  eventId: 101,
                  eventName: 'Event',
                  userId: 10,
                  userFullName: 'User',
                  registerTime: null,
                  status: 'Registered',
                  registrationStatus: RegistrationStatus.registered,
                  cancellationReason: null,
                  createdDate: null,
                ),
              ),
            ),
          ),
          registerEventUseCase: RegisterEventUseCase(
            repository: registerRepository,
          ),
          cancelRegistrationUseCase: CancelRegistrationUseCase(
            repository: _FakeCancelRegistrationRepository(),
          ),
          checkAttendanceStatusUseCase: CheckAttendanceStatusUseCase(
            repository: _FakeAttendanceStatusRepository(),
          ),
          notifyEventChanged: notifiedIds.add,
        );
        addTearDown(notifier.dispose);

        await notifier.registerForEvent();
        await Future<void>.delayed(Duration.zero);

        expect(registerRepository.callCount, 1);
        expect(notifiedIds, <int>[101]);
        expect(notifier.state.feedbackMessage, 'Đăng ký sự kiện thành công.');
        expect(notifier.state.isRegistering, isFalse);
      },
    );

    test(
      'registerForEvent keeps backend overlap message for time conflict',
      () async {
        final notifiedIds = <int>[];
        final registerRepository = _FakeRegisterEventRepository()
          ..onRegisterEvent = ({required eventId}) async {
            throw const AppError(
              type: AppErrorType.badRequest,
              statusCode: 400,
              message:
                  'Bạn đã đăng ký sự kiện "Sự kiện đang trùng" bị trùng thời gian với sự kiện này',
              isBackendMessage: true,
            );
          };
        final notifier = EventDetailNotifier(
          eventId: 101,
          getEventDetailUseCase: GetEventDetailUseCase(
            repository: _FakeEventDetailRepository(),
          ),
          getMyRegistrationUseCase: GetMyRegistrationUseCase(
            repository: _FakeMyRegistrationRepository(),
          ),
          registerEventUseCase: RegisterEventUseCase(
            repository: registerRepository,
          ),
          cancelRegistrationUseCase: CancelRegistrationUseCase(
            repository: _FakeCancelRegistrationRepository(),
          ),
          checkAttendanceStatusUseCase: CheckAttendanceStatusUseCase(
            repository: _FakeAttendanceStatusRepository(),
          ),
          notifyEventChanged: notifiedIds.add,
        );
        addTearDown(notifier.dispose);

        await notifier.registerForEvent();

        expect(registerRepository.callCount, 1);
        expect(notifiedIds, isEmpty);
        expect(
          notifier.state.feedbackMessage,
          'Bạn đã đăng ký sự kiện "Sự kiện đang trùng" bị trùng thời gian với sự kiện này',
        );
        expect(notifier.state.registrationState?.isRegistered, isNot(isTrue));
        expect(notifier.state.isRegistering, isFalse);
      },
    );

    test(
      'cancelRegistration updates UI back to notRegistered immediately',
      () async {
        final notifiedIds = <int>[];
        final eventDetailRepository = _FakeEventDetailRepository(
          detailBuilder: (eventId) => EventDetail(
            eventId: eventId,
            eventName: 'Event $eventId',
            description: 'Desc',
            startTime: DateTime(2026, 1, 1, 8),
            endTime: DateTime(2026, 1, 1, 10),
            locationName: 'Hall A',
            latitude: 10.0,
            longitude: 106.0,
            allowRadius: 50,
            maxParticipants: 100,
            currentParticipants: 100,
            status: 1,
            statusName: 'Open',
            eventType: const EventDetailTypeInfo(
              typeId: 1,
              typeName: 'Workshop',
              description: null,
            ),
            institute: const EventDetailInstituteInfo(
              instituteId: 2,
              instituteName: 'Institute',
            ),
            registrationDeadline: DateTime(2026, 12, 31),
            images: const <EventDetailImage>[],
            createdByName: 'Admin',
            createdDate: DateTime(2025, 12, 1),
            hasAvailableSlots: false,
            isRegistrationClosed: false,
            enableFaceVerification: false,
          ),
        );
        final notifier = EventDetailNotifier(
          eventId: 101,
          getEventDetailUseCase: GetEventDetailUseCase(
            repository: eventDetailRepository,
          ),
          getMyRegistrationUseCase: GetMyRegistrationUseCase(
            repository: _FakeMyRegistrationRepository(
              state: MyRegistrationState.registered(
                const MyRegistrationInfo(
                  registrationId: 1,
                  eventId: 101,
                  eventName: 'Event',
                  userId: 10,
                  userFullName: 'User',
                  registerTime: null,
                  status: 'Registered',
                  registrationStatus: RegistrationStatus.registered,
                  cancellationReason: null,
                  createdDate: null,
                ),
              ),
            ),
          ),
          registerEventUseCase: RegisterEventUseCase(
            repository: _FakeRegisterEventRepository(),
          ),
          cancelRegistrationUseCase: CancelRegistrationUseCase(
            repository: _FakeCancelRegistrationRepository(),
          ),
          checkAttendanceStatusUseCase: CheckAttendanceStatusUseCase(
            repository: _FakeAttendanceStatusRepository(),
          ),
          notifyEventChanged: notifiedIds.add,
        );
        addTearDown(notifier.dispose);

        await notifier.syncInitial();
        await notifier.cancelRegistration();

        expect(notifiedIds, <int>[101]);
        expect(notifier.state.registrationState?.isRegistered, isFalse);
        expect(notifier.state.eventDetail?.hasAvailableSlots, isTrue);
        expect(notifier.state.eventDetail?.currentParticipants, 99);
        expect(notifier.state.feedbackMessage, 'Hủy đăng ký thành công.');
        expect(notifier.state.isCancelling, isFalse);
      },
    );
  });
}

class _FakeEventDetailRepository implements EventDetailRepository {
  _FakeEventDetailRepository({this.detailBuilder});

  int callCount = 0;
  final EventDetail Function(int eventId)? detailBuilder;

  @override
  Future<EventDetail> getEventDetail({required int eventId}) async {
    callCount += 1;
    final override = detailBuilder;
    if (override != null) {
      return override(eventId);
    }
    return EventDetail(
      eventId: eventId,
      eventName: 'Event $eventId',
      description: 'Desc',
      startTime: DateTime(2026, 1, 1, 8),
      endTime: DateTime(2026, 1, 1, 10),
      locationName: 'Hall A',
      latitude: 10.0,
      longitude: 106.0,
      allowRadius: 50,
      maxParticipants: 100,
      currentParticipants: 10,
      status: 1,
      statusName: 'Open',
      eventType: const EventDetailTypeInfo(
        typeId: 1,
        typeName: 'Workshop',
        description: null,
      ),
      institute: const EventDetailInstituteInfo(
        instituteId: 2,
        instituteName: 'Institute',
      ),
      registrationDeadline: DateTime(2025, 12, 31),
      images: const <EventDetailImage>[],
      createdByName: 'Admin',
      createdDate: DateTime(2025, 12, 1),
      hasAvailableSlots: true,
      isRegistrationClosed: false,
      enableFaceVerification: false,
    );
  }
}

class _FakeMyRegistrationRepository implements MyRegistrationRepository {
  _FakeMyRegistrationRepository({
    this.state = const MyRegistrationState.notRegistered(),
  });

  int callCount = 0;
  final MyRegistrationState state;

  @override
  Future<MyRegistrationState> getMyRegistration({required int eventId}) async {
    callCount += 1;
    return state;
  }
}

class _FakeRegisterEventRepository implements RegisterEventRepository {
  int callCount = 0;
  Future<RegisterEventResult> Function({required int eventId})? onRegisterEvent;

  @override
  Future<RegisterEventResult> registerEvent({required int eventId}) async {
    callCount += 1;
    final override = onRegisterEvent;
    if (override != null) {
      return override(eventId: eventId);
    }
    return _registerResult(eventId: eventId);
  }
}

class _FakeCancelRegistrationRepository
    implements CancelRegistrationRepository {
  @override
  Future<CancelRegistrationResult> cancelRegistration({
    required int eventId,
    String? cancellationReason,
  }) async {
    return CancelRegistrationResult(
      registrationId: 1,
      eventId: eventId,
      eventName: 'Event',
      userId: 10,
      userFullName: 'User',
      registerTime: DateTime(2026, 1, 1),
      status: 'Cancelled',
      registrationStatus: RegistrationStatus.cancelled,
      cancellationReason: cancellationReason,
      createdDate: DateTime(2026, 1, 1),
    );
  }
}

class _FakeAttendanceStatusRepository
    implements CheckAttendanceStatusRepository {
  _FakeAttendanceStatusRepository({
    this.state = const AttendanceCheckStatus(
      eventId: 0,
      hasCheckedIn: false,
      isValid: null,
      invalidReason: null,
    ),
  });

  int callCount = 0;
  final AttendanceCheckStatus state;

  @override
  Future<AttendanceCheckStatus> getAttendanceCheckStatus({
    required int eventId,
  }) async {
    callCount += 1;
    return AttendanceCheckStatus(
      eventId: eventId,
      hasCheckedIn: state.hasCheckedIn,
      isValid: state.isValid,
      invalidReason: state.invalidReason,
    );
  }
}

RegisterEventResult _registerResult({required int eventId}) {
  return RegisterEventResult(
    registrationId: 1,
    eventId: eventId,
    eventName: 'Event',
    userId: 10,
    userFullName: 'User',
    registerTime: DateTime(2026, 1, 1),
    status: 'Registered',
    registrationStatus: RegistrationStatus.registered,
    cancellationReason: null,
    createdDate: DateTime(2026, 1, 1),
  );
}
