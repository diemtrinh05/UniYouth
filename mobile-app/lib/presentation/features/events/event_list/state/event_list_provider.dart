import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/providers/app_provider_graph.dart';
import '../../../../../../domain/usecases/events/get_events_usecase.dart';
import 'event_list_notifier.dart';
import 'event_list_state.dart';

class EventListNotifierDependencies {
  const EventListNotifierDependencies({
    required this.getEventsUseCase,
    this.eventChangedStream,
    this.defaultPageSize = 10,
  });

  final GetEventsUseCase getEventsUseCase;
  final Stream<int>? eventChangedStream;
  final int defaultPageSize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EventListNotifierDependencies &&
        other.getEventsUseCase == getEventsUseCase &&
        other.eventChangedStream == eventChangedStream &&
        other.defaultPageSize == defaultPageSize;
  }

  @override
  int get hashCode =>
      Object.hash(getEventsUseCase, eventChangedStream, defaultPageSize);
}

final eventListNotifierProvider =
    StateNotifierProvider.autoDispose<EventListNotifier, EventListState>((ref) {
      return EventListNotifier(
        getEventsUseCase: ref.watch(getEventsUseCaseProvider),
      );
    });

final eventListNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<EventListNotifier, EventListState, EventListNotifierDependencies>((
      ref,
      dependencies,
    ) {
      return EventListNotifier(
        getEventsUseCase: dependencies.getEventsUseCase,
        eventChangedStream: dependencies.eventChangedStream,
        defaultPageSize: dependencies.defaultPageSize,
      );
    });
