import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../core/error/error_presenter.dart';
import '../../../../../../domain/usecases/events/get_event_types_usecase.dart';
import 'event_filters_state.dart';

class EventFiltersNotifier extends StateNotifier<EventFiltersState> {
  EventFiltersNotifier({required GetEventTypesUseCase getEventTypesUseCase})
    : _getEventTypesUseCase = getEventTypesUseCase,
      super(const EventFiltersState());

  final GetEventTypesUseCase _getEventTypesUseCase;
  bool _isDisposed = false;

  Future<void> syncInitial({bool useCache = true}) async {
    _setState(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final result = await _getEventTypesUseCase(useCache: useCache);
      _setState(
        state.copyWith(
          eventTypes: List<EventTypeItem>.unmodifiable(result),
          clearErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          errorMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'tải danh mục loại sự kiện',
          ).message,
        ),
      );
    } finally {
      _setState(state.copyWith(isLoading: false));
    }
  }

  void toggleSelectedIndex(int index) {
    if (state.selectedIndex == index) {
      _setState(state.copyWith(clearSelectedIndex: true));
      return;
    }
    _setState(state.copyWith(selectedIndex: index));
  }

  void _setState(EventFiltersState nextState) {
    if (_isDisposed) {
      return;
    }
    state = nextState;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
