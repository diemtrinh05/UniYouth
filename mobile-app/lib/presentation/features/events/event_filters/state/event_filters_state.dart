import '../../../../../../domain/usecases/events/get_event_types_usecase.dart';

class EventFiltersState {
  const EventFiltersState({
    this.isLoading = true,
    this.errorMessage,
    this.eventTypes = const <EventTypeItem>[],
    this.selectedIndex,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<EventTypeItem> eventTypes;
  final int? selectedIndex;

  EventFiltersState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<EventTypeItem>? eventTypes,
    int? selectedIndex,
    bool clearSelectedIndex = false,
  }) {
    return EventFiltersState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      eventTypes: eventTypes ?? this.eventTypes,
      selectedIndex: clearSelectedIndex
          ? null
          : (selectedIndex ?? this.selectedIndex),
    );
  }
}
