import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/providers/app_provider_graph.dart';
import '../../../../../../domain/usecases/attendance/check_attendance_status_usecase.dart';
import '../../../../../../domain/usecases/events/get_event_detail_usecase.dart';
import '../../../../../../domain/usecases/registration/cancel_registration_usecase.dart';
import '../../../../../../domain/usecases/registration/get_my_registration_usecase.dart';
import '../../../../../../domain/usecases/registration/register_event_usecase.dart';
import 'event_detail_notifier.dart';
import 'event_detail_state.dart';

class EventDetailNotifierDependencies {
  const EventDetailNotifierDependencies({
    required this.eventId,
    required this.getEventDetailUseCase,
    required this.getMyRegistrationUseCase,
    required this.registerEventUseCase,
    required this.cancelRegistrationUseCase,
    required this.checkAttendanceStatusUseCase,
    required this.notifyEventChanged,
  });

  final int eventId;
  final GetEventDetailUseCase getEventDetailUseCase;
  final GetMyRegistrationUseCase getMyRegistrationUseCase;
  final RegisterEventUseCase registerEventUseCase;
  final CancelRegistrationUseCase cancelRegistrationUseCase;
  final CheckAttendanceStatusUseCase checkAttendanceStatusUseCase;
  final void Function(int eventId) notifyEventChanged;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EventDetailNotifierDependencies &&
        other.eventId == eventId &&
        other.getEventDetailUseCase == getEventDetailUseCase &&
        other.getMyRegistrationUseCase == getMyRegistrationUseCase &&
        other.registerEventUseCase == registerEventUseCase &&
        other.cancelRegistrationUseCase == cancelRegistrationUseCase &&
        other.checkAttendanceStatusUseCase == checkAttendanceStatusUseCase &&
        other.notifyEventChanged == notifyEventChanged;
  }

  @override
  int get hashCode {
    return Object.hash(
      eventId,
      getEventDetailUseCase,
      getMyRegistrationUseCase,
      registerEventUseCase,
      cancelRegistrationUseCase,
      checkAttendanceStatusUseCase,
      notifyEventChanged,
    );
  }
}

final eventDetailNotifierProvider =
    StateNotifierProvider.autoDispose.family<
      EventDetailNotifier,
      EventDetailState,
      int
    >((ref, eventId) {
      return EventDetailNotifier(
        eventId: eventId,
        getEventDetailUseCase: ref.watch(getEventDetailUseCaseProvider),
        getMyRegistrationUseCase: ref.watch(getMyRegistrationUseCaseProvider),
        registerEventUseCase: ref.watch(registerEventUseCaseProvider),
        cancelRegistrationUseCase: ref.watch(cancelRegistrationUseCaseProvider),
        checkAttendanceStatusUseCase: ref.watch(checkAttendanceStatusUseCaseProvider),
        notifyEventChanged: ref
            .watch(eventRefreshSignalProvider.notifier)
            .notifyEventChanged,
      );
    });

final eventDetailNotifierByDependenciesProvider =
    StateNotifierProvider.autoDispose.family<
      EventDetailNotifier,
      EventDetailState,
      EventDetailNotifierDependencies
    >((ref, dependencies) {
      return EventDetailNotifier(
        eventId: dependencies.eventId,
        getEventDetailUseCase: dependencies.getEventDetailUseCase,
        getMyRegistrationUseCase: dependencies.getMyRegistrationUseCase,
        registerEventUseCase: dependencies.registerEventUseCase,
        cancelRegistrationUseCase: dependencies.cancelRegistrationUseCase,
        checkAttendanceStatusUseCase: dependencies.checkAttendanceStatusUseCase,
        notifyEventChanged: dependencies.notifyEventChanged,
      );
    });
