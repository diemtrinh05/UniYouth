import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/providers/app_provider_graph.dart';
import '../../../../../../domain/usecases/events/get_event_types_usecase.dart';
import 'event_filters_notifier.dart';
import 'event_filters_state.dart';

class EventFiltersNotifierDependencies {
  const EventFiltersNotifierDependencies({required this.getEventTypesUseCase});

  final GetEventTypesUseCase getEventTypesUseCase;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is EventFiltersNotifierDependencies &&
        other.getEventTypesUseCase == getEventTypesUseCase;
  }

  @override
  int get hashCode => getEventTypesUseCase.hashCode;
}

final eventFiltersNotifierProvider =
    StateNotifierProvider.autoDispose<EventFiltersNotifier, EventFiltersState>((
      ref,
    ) {
      return EventFiltersNotifier(
        getEventTypesUseCase: ref.watch(getEventTypesUseCaseProvider),
      );
    });

final eventFiltersNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      EventFiltersNotifier,
      EventFiltersState,
      EventFiltersNotifierDependencies
    >((ref, dependencies) {
      return EventFiltersNotifier(
        getEventTypesUseCase: dependencies.getEventTypesUseCase,
      );
    });
