import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../core/error/app_error_type.dart';
import '../../../../../../core/error/error_presenter.dart';
import '../../../../../../core/network/retry_policy/rate_limit_policy.dart';
import '../../../../../../domain/usecases/attendance/check_attendance_status_usecase.dart';
import '../../../../../../domain/usecases/events/get_event_detail_usecase.dart';
import '../../../../../../domain/usecases/registration/cancel_registration_usecase.dart';
import '../../../../../../domain/usecases/registration/get_my_registration_usecase.dart';
import '../../../../../../domain/usecases/registration/register_event_usecase.dart';
import 'event_detail_state.dart';

class EventDetailNotifier extends StateNotifier<EventDetailState> {
  EventDetailNotifier({
    required int eventId,
    required GetEventDetailUseCase getEventDetailUseCase,
    required GetMyRegistrationUseCase getMyRegistrationUseCase,
    required RegisterEventUseCase registerEventUseCase,
    required CancelRegistrationUseCase cancelRegistrationUseCase,
    required CheckAttendanceStatusUseCase checkAttendanceStatusUseCase,
    required void Function(int eventId) notifyEventChanged,
  }) : _eventId = eventId,
       _getEventDetailUseCase = getEventDetailUseCase,
       _getMyRegistrationUseCase = getMyRegistrationUseCase,
       _registerEventUseCase = registerEventUseCase,
       _cancelRegistrationUseCase = cancelRegistrationUseCase,
       _checkAttendanceStatusUseCase = checkAttendanceStatusUseCase,
       _notifyEventChanged = notifyEventChanged,
       super(const EventDetailState());

  final int _eventId;
  final GetEventDetailUseCase _getEventDetailUseCase;
  final GetMyRegistrationUseCase _getMyRegistrationUseCase;
  final RegisterEventUseCase _registerEventUseCase;
  final CancelRegistrationUseCase _cancelRegistrationUseCase;
  final CheckAttendanceStatusUseCase _checkAttendanceStatusUseCase;
  final void Function(int eventId) _notifyEventChanged;

  Timer? _registerCooldownTimer;
  bool _isDisposed = false;

  Future<void> syncInitial() {
    return refreshData();
  }

  Future<void> refreshData() async {
    await Future.wait<void>([
      loadEventDetail(),
      loadMyRegistrationStatus(),
      loadAttendanceStatus(),
    ]);
  }

  Future<void> loadEventDetail() async {
    _setState(state.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      final detail = await _getEventDetailUseCase(eventId: _eventId);
      _setState(
        state.copyWith(
          eventDetail: detail,
          isLoading: false,
          clearErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'tải chi tiết sự kiện',
          ).message,
        ),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorPresenter.presentException(
            operation: 'tải chi tiết sự kiện',
          ).message,
        ),
      );
    }
  }

  Future<void> loadMyRegistrationStatus() async {
    _setState(
      state.copyWith(
        isRegistrationLoading: true,
        clearRegistrationErrorMessage: true,
      ),
    );
    try {
      final registrationState = await _getMyRegistrationUseCase(
        eventId: _eventId,
      );
      _setState(
        state.copyWith(
          registrationState: registrationState,
          isRegistrationLoading: false,
          clearRegistrationErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isRegistrationLoading: false,
          registrationErrorMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'tải trạng thái đăng ký',
          ).message,
        ),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          isRegistrationLoading: false,
          registrationErrorMessage: ErrorPresenter.presentException(
            operation: 'tải trạng thái đăng ký',
          ).message,
        ),
      );
    }
  }

  Future<void> loadAttendanceStatus() async {
    _setState(
      state.copyWith(
        isAttendanceStatusLoading: true,
        clearAttendanceStatusErrorMessage: true,
      ),
    );
    try {
      final attendanceStatus = await _checkAttendanceStatusUseCase(
        eventId: _eventId,
      );
      _setState(
        state.copyWith(
          attendanceStatus: attendanceStatus,
          isAttendanceStatusLoading: false,
          clearAttendanceStatusErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isAttendanceStatusLoading: false,
          attendanceStatusErrorMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'tải trạng thái điểm danh',
          ).message,
        ),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          isAttendanceStatusLoading: false,
          attendanceStatusErrorMessage: ErrorPresenter.presentException(
            operation: 'tải trạng thái điểm danh',
          ).message,
        ),
      );
    }
  }

  Future<void> registerForEvent() async {
    if (state.isRegistering || state.isRegisterRateLimited) {
      return;
    }
    _setState(state.copyWith(isRegistering: true, clearFeedbackMessage: true));
    try {
      final result = await _registerEventUseCase(eventId: _eventId);
      _setState(
        state.copyWith(
          registrationState: MyRegistrationState.registered(
            _toMyRegistrationInfo(result),
          ),
          feedbackMessage: 'Đăng ký sự kiện thành công.',
        ),
      );
      _notifyEventChanged(_eventId);
      unawaited(refreshData());
    } on AppError catch (error) {
      if (error.statusCode == 429) {
        _startRegisterCooldown();
      }
      _setState(
        state.copyWith(feedbackMessage: _mapRegisterErrorMessage(error)),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentException(
            operation: 'đăng ký sự kiện',
          ).message,
        ),
      );
    } finally {
      _setState(state.copyWith(isRegistering: false));
    }
  }

  Future<void> cancelRegistration({String? cancellationReason}) async {
    if (state.isCancelling) {
      return;
    }
    _setState(state.copyWith(isCancelling: true, clearFeedbackMessage: true));
    try {
      await _cancelRegistrationUseCase(
        eventId: _eventId,
        cancellationReason: cancellationReason?.trim().isEmpty ?? true
            ? null
            : cancellationReason!.trim(),
      );
      final updatedDetail = _applyCancellationToEventDetail(state.eventDetail);
      _setState(
        state.copyWith(
          registrationState: const MyRegistrationState.notRegistered(),
          eventDetail: updatedDetail,
          feedbackMessage: 'Hủy đăng ký thành công.',
        ),
      );
      _notifyEventChanged(_eventId);
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'hủy đăng ký',
          ).message,
        ),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentException(
            operation: 'hủy đăng ký',
          ).message,
        ),
      );
    } finally {
      _setState(state.copyWith(isCancelling: false));
    }
  }

  void setOpeningCheckIn(bool isOpening) {
    if (state.isOpeningCheckIn == isOpening) {
      return;
    }
    _setState(state.copyWith(isOpeningCheckIn: isOpening));
  }

  Future<void> handleCheckInResult({required bool didCheckIn}) async {
    if (!didCheckIn) {
      return;
    }
    await loadAttendanceStatus();
  }

  void clearFeedbackMessage() {
    if (state.feedbackMessage == null) {
      return;
    }
    _setState(state.copyWith(clearFeedbackMessage: true));
  }

  void clearErrorMessage() {
    if (state.errorMessage == null) {
      return;
    }
    _setState(state.copyWith(clearErrorMessage: true));
  }

  void clearRegistrationErrorMessage() {
    if (state.registrationErrorMessage == null) {
      return;
    }
    _setState(state.copyWith(clearRegistrationErrorMessage: true));
  }

  void clearAttendanceStatusErrorMessage() {
    if (state.attendanceStatusErrorMessage == null) {
      return;
    }
    _setState(state.copyWith(clearAttendanceStatusErrorMessage: true));
  }

  MyRegistrationInfo _toMyRegistrationInfo(RegisterEventResult result) =>
      MyRegistrationInfo(
        registrationId: result.registrationId,
        eventId: result.eventId,
        eventName: result.eventName,
        userId: result.userId,
        userFullName: result.userFullName,
        registerTime: result.registerTime,
        status: result.status,
        registrationStatus: result.registrationStatus,
        cancellationReason: result.cancellationReason,
        createdDate: result.createdDate,
      );

  EventDetail? _applyCancellationToEventDetail(EventDetail? detail) {
    if (detail == null) {
      return null;
    }

    final currentParticipants = detail.currentParticipants;
    final nextParticipants = currentParticipants == null
        ? null
        : (currentParticipants > 0 ? currentParticipants - 1 : 0);

    return EventDetail(
      eventId: detail.eventId,
      eventName: detail.eventName,
      description: detail.description,
      startTime: detail.startTime,
      endTime: detail.endTime,
      locationName: detail.locationName,
      latitude: detail.latitude,
      longitude: detail.longitude,
      allowRadius: detail.allowRadius,
      maxParticipants: detail.maxParticipants,
      currentParticipants: nextParticipants,
      status: detail.status,
      statusName: detail.statusName,
      eventType: detail.eventType,
      institute: detail.institute,
      registrationDeadline: detail.registrationDeadline,
      images: detail.images,
      createdByName: detail.createdByName,
      createdDate: detail.createdDate,
      hasAvailableSlots: detail.isRegistrationClosed ? false : true,
      isRegistrationClosed: detail.isRegistrationClosed,
      enableFaceVerification: detail.enableFaceVerification,
    );
  }

  void _startRegisterCooldown() {
    final duration = RateLimitPolicy.cooldownFor(
      SensitiveApiAction.eventRegister,
    );
    _registerCooldownTimer?.cancel();
    _setState(state.copyWith(registerCooldownSeconds: duration.inSeconds));
    _registerCooldownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      final nextSeconds = state.registerCooldownSeconds - 1;
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      if (nextSeconds > 0) {
        _setState(state.copyWith(registerCooldownSeconds: nextSeconds));
        return;
      }
      timer.cancel();
      _setState(state.copyWith(registerCooldownSeconds: 0));
    });
  }

  String _mapRegisterErrorMessage(AppError error) {
    if (error.statusCode == 429 && state.isRegisterRateLimited) {
      return RateLimitPolicy.cooldownMessage(
        seconds: state.registerCooldownSeconds,
        backendMessage: error.message,
      );
    }
    if (_isRegistrationTimeConflictError(error)) {
      return error.message.trim();
    }
    if (error.type == AppErrorType.network) {
      return 'Không thể kết nối tới máy chủ.';
    }
    return ErrorPresenter.presentAppError(
      error,
      operation: 'đăng ký sự kiện',
    ).message;
  }

  bool _isRegistrationTimeConflictError(AppError error) {
    if (error.statusCode != 400) {
      return false;
    }

    final normalizedMessage = error.message.trim().toLowerCase();
    if (normalizedMessage.isEmpty) {
      return false;
    }

    return normalizedMessage.contains('trùng thời gian');
  }

  void _setState(EventDetailState nextState) {
    if (_isDisposed) {
      return;
    }
    state = nextState;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _registerCooldownTimer?.cancel();
    super.dispose();
  }
}
