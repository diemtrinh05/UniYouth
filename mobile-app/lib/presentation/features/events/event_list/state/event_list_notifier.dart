import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../domain/usecases/events/get_events_usecase.dart';
import '../../../../shared/mappers/app_error_ui_mapper.dart';
import 'event_list_state.dart';

class EventListNotifier extends StateNotifier<EventListState> {
  EventListNotifier({
    required GetEventsUseCase getEventsUseCase,
    Stream<int>? eventChangedStream,
    int defaultPageSize = 10,
  }) : _getEventsUseCase = getEventsUseCase,
       _defaultPageSize = defaultPageSize,
       super(EventListState(pageSize: defaultPageSize)) {
    if (eventChangedStream != null) {
      _eventChangedSubscription = eventChangedStream.listen((eventId) {
        _onEventChanged(eventId);
      });
    }
  }

  final GetEventsUseCase _getEventsUseCase;
  final int _defaultPageSize;

  StreamSubscription<int>? _eventChangedSubscription;
  bool _isDisposed = false;

  Future<void> syncInitial() async {
    _setState(
      state.copyWith(
        isInitialLoading: true,
        isLoadingMore: false,
        clearErrorMessage: true,
      ),
    );

    try {
      final result = await _getEventsUseCase(
        filter: EventListFilter(
          pageNumber: 1,
          pageSize: _defaultPageSize,
          q: state.query,
          status: state.status,
          sortBy: state.sortBy,
          sortDir: state.sortDir,
          eventTypeId: state.eventTypeId,
          instituteId: state.instituteId,
          startDate: state.startDate,
          endDate: state.endDate,
        ),
      );

      _setState(
        state.copyWith(
          items: List<EventListItem>.unmodifiable(result.items),
          totalCount: result.totalCount,
          currentPage: result.pageNumber,
          pageSize: result.pageSize,
          totalPages: result.totalPages,
          hasPreviousPage: result.hasPreviousPage,
          hasNextPage: result.hasNextPage,
          isInitialLoading: false,
          isLoadingMore: false,
          clearErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          errorMessage: AppErrorUiMapper.message(
            error,
            operation: 'tải danh sách sự kiện',
          ),
        ),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          errorMessage: AppErrorUiMapper.exceptionMessage(
            operation: 'tải danh sách sự kiện',
          ),
        ),
      );
    }
  }

  Future<void> refresh() {
    return syncInitial();
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    _setState(state.copyWith(isLoadingMore: true, clearErrorMessage: true));

    try {
      final result = await _getEventsUseCase(
        filter: EventListFilter(
          pageNumber: state.currentPage + 1,
          pageSize: state.pageSize,
          q: state.query,
          status: state.status,
          sortBy: state.sortBy,
          sortDir: state.sortDir,
          eventTypeId: state.eventTypeId,
          instituteId: state.instituteId,
          startDate: state.startDate,
          endDate: state.endDate,
        ),
      );

      final mergedItems = List<EventListItem>.from(state.items)
        ..addAll(result.items);
      _setState(
        state.copyWith(
          items: List<EventListItem>.unmodifiable(mergedItems),
          totalCount: result.totalCount,
          currentPage: result.pageNumber,
          pageSize: result.pageSize,
          totalPages: result.totalPages,
          hasPreviousPage: result.hasPreviousPage,
          hasNextPage: result.hasNextPage,
          isLoadingMore: false,
          clearErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: AppErrorUiMapper.message(
            error,
            operation: 'tải thêm sự kiện',
          ),
        ),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: AppErrorUiMapper.exceptionMessage(
            operation: 'tải thêm sự kiện',
          ),
        ),
      );
    }
  }

  Future<void> applyFilters({
    required String eventTypeIdText,
    required String instituteIdText,
  }) async {
    final parsedEventTypeId = _parseOptionalInt(
      eventTypeIdText,
      fieldName: 'eventTypeId',
    );
    final parsedInstituteId = _parseOptionalInt(
      instituteIdText,
      fieldName: 'instituteId',
    );

    if (state.startDate != null &&
        state.endDate != null &&
        state.startDate!.isAfter(state.endDate!)) {
      throw const FormatException('startDate phải nhỏ hơn hoặc bằng endDate.');
    }

    _setState(
      state.copyWith(
        sortBy: 'eventId',
        sortDir: 'desc',
        eventTypeId: parsedEventTypeId,
        instituteId: parsedInstituteId,
        clearErrorMessage: true,
      ),
    );
    await syncInitial();
  }

  Future<void> clearFilters() async {
    _setState(
      state.copyWith(
        clearQuery: true,
        clearStatus: true,
        sortBy: 'eventId',
        sortDir: 'desc',
        clearEventTypeId: true,
        clearInstituteId: true,
        clearStartDate: true,
        clearEndDate: true,
        clearErrorMessage: true,
      ),
    );
    await syncInitial();
  }

  Future<void> search(String query) async {
    final normalized = query.trim();
    _setState(
      state.copyWith(
        query: normalized,
        clearQuery: normalized.isEmpty,
        clearErrorMessage: true,
      ),
    );
    await syncInitial();
  }

  void selectStatus(int? status) {
    _setState(
      state.copyWith(
        status: status,
        clearStatus: status == null,
        sortBy: 'eventId',
        sortDir: 'desc',
      ),
    );
  }

  void setStartDate(DateTime? startDate) {
    if (startDate == null) {
      _setState(state.copyWith(clearStartDate: true));
      return;
    }
    _setState(
      state.copyWith(
        startDate: DateTime(startDate.year, startDate.month, startDate.day),
      ),
    );
  }

  void setEndDate(DateTime? endDate) {
    if (endDate == null) {
      _setState(state.copyWith(clearEndDate: true));
      return;
    }
    _setState(
      state.copyWith(
        endDate: DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        ),
      ),
    );
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }
    _setState(state.copyWith(clearErrorMessage: true));
  }

  int? parseOptionalInt(String value, {required String fieldName}) {
    return _parseOptionalInt(value, fieldName: fieldName);
  }

  void _onEventChanged(int _) {
    unawaited(syncInitial());
  }

  int? _parseOptionalInt(String value, {required String fieldName}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      throw FormatException('$fieldName không hợp lệ.');
    }
    return parsed;
  }

  void _setState(EventListState nextState) {
    if (_isDisposed) {
      return;
    }
    state = nextState;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _eventChangedSubscription?.cancel();
    super.dispose();
  }
}
