import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/event_type_repository_impl.dart';
import '../../../data/repositories/events_repository_impl.dart';
import '../../../domain/usecases/events/get_event_detail_usecase.dart';
import '../../../domain/usecases/events/get_home_event_preview_usecase.dart';
import '../../../domain/usecases/events/get_event_types_usecase.dart';
import '../../../domain/usecases/events/get_events_usecase.dart';
import '../../../domain/usecases/registration/cancel_registration_usecase.dart';
import '../../../domain/usecases/registration/get_my_registration_usecase.dart';
import '../../../domain/usecases/registration/register_event_usecase.dart';
import 'app_foundation_providers.dart';

final eventTypeRepositoryProvider = Provider<EventTypeRepositoryImpl>(
  (ref) => EventTypeRepositoryImpl(
    remoteDataSource: ref.watch(eventTypeRemoteDataSourceProvider),
  ),
);

final eventsRepositoryProvider = Provider<EventsRepositoryImpl>(
  (ref) => EventsRepositoryImpl(
    remoteDataSource: ref.watch(eventsRemoteDataSourceProvider),
    idempotencyKeyProvider: ref.watch(idempotencyKeyProviderProvider),
  ),
);

final getEventTypesUseCaseProvider = Provider<GetEventTypesUseCase>(
  (ref) =>
      GetEventTypesUseCase(repository: ref.watch(eventTypeRepositoryProvider)),
);

final getEventsUseCaseProvider = Provider<GetEventsUseCase>(
  (ref) => GetEventsUseCase(repository: ref.watch(eventsRepositoryProvider)),
);

final getEventDetailUseCaseProvider = Provider<GetEventDetailUseCase>(
  (ref) =>
      GetEventDetailUseCase(repository: ref.watch(eventsRepositoryProvider)),
);

final getHomeEventPreviewUseCaseProvider = Provider<GetHomeEventPreviewUseCase>(
  (ref) => GetHomeEventPreviewUseCase(
    repository: ref.watch(eventsRepositoryProvider),
  ),
);

final getMyRegistrationUseCaseProvider = Provider<GetMyRegistrationUseCase>(
  (ref) =>
      GetMyRegistrationUseCase(repository: ref.watch(eventsRepositoryProvider)),
);

final registerEventUseCaseProvider = Provider<RegisterEventUseCase>(
  (ref) =>
      RegisterEventUseCase(repository: ref.watch(eventsRepositoryProvider)),
);

final cancelRegistrationUseCaseProvider = Provider<CancelRegistrationUseCase>(
  (ref) => CancelRegistrationUseCase(
    repository: ref.watch(eventsRepositoryProvider),
  ),
);

class EventRefreshSignal {
  const EventRefreshSignal({required this.revision, required this.eventId});

  const EventRefreshSignal.initial() : this(revision: 0, eventId: null);

  final int revision;
  final int? eventId;
}

class EventRefreshSignalController extends Notifier<EventRefreshSignal> {
  @override
  EventRefreshSignal build() => const EventRefreshSignal.initial();

  void notifyEventChanged(int eventId) {
    state = EventRefreshSignal(revision: state.revision + 1, eventId: eventId);
  }
}

final eventRefreshSignalProvider =
    NotifierProvider<EventRefreshSignalController, EventRefreshSignal>(
      EventRefreshSignalController.new,
    );

class EventsNavigationBindings {
  const EventsNavigationBindings({
    required this.getEventTypesUseCase,
    required this.getEventsUseCase,
    required this.getHomeEventPreviewUseCase,
    required this.getEventDetailUseCase,
    required this.getMyRegistrationUseCase,
    required this.registerEventUseCase,
    required this.cancelRegistrationUseCase,
  });

  final GetEventTypesUseCase Function() getEventTypesUseCase;
  final GetEventsUseCase Function() getEventsUseCase;
  final GetHomeEventPreviewUseCase Function() getHomeEventPreviewUseCase;
  final GetEventDetailUseCase Function() getEventDetailUseCase;
  final GetMyRegistrationUseCase Function() getMyRegistrationUseCase;
  final RegisterEventUseCase Function() registerEventUseCase;
  final CancelRegistrationUseCase Function() cancelRegistrationUseCase;
}

final eventsNavigationBindingsProvider = Provider<EventsNavigationBindings>((
  ref,
) {
  final read = ref.read;
  return EventsNavigationBindings(
    getEventTypesUseCase: () => read(getEventTypesUseCaseProvider),
    getEventsUseCase: () => read(getEventsUseCaseProvider),
    getHomeEventPreviewUseCase: () => read(getHomeEventPreviewUseCaseProvider),
    getEventDetailUseCase: () => read(getEventDetailUseCaseProvider),
    getMyRegistrationUseCase: () => read(getMyRegistrationUseCaseProvider),
    registerEventUseCase: () => read(registerEventUseCaseProvider),
    cancelRegistrationUseCase: () => read(cancelRegistrationUseCaseProvider),
  );
});
