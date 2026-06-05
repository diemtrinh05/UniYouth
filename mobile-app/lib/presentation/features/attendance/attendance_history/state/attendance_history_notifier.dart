import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../domain/usecases/attendance/get_my_history_usecase.dart';
import '../../../../shared/mappers/app_error_ui_mapper.dart';
import 'attendance_history_state.dart';

class AttendanceHistoryNotifier extends StateNotifier<AttendanceHistoryState> {
  AttendanceHistoryNotifier({
    required GetMyHistoryUseCase getMyHistoryUseCase,
    int defaultPageSize = 20,
  }) : _getMyHistoryUseCase = getMyHistoryUseCase,
       _defaultPageSize = defaultPageSize,
       super(AttendanceHistoryState(pageSize: defaultPageSize));

  final GetMyHistoryUseCase _getMyHistoryUseCase;
  final int _defaultPageSize;

  bool _isDisposed = false;

  Future<void> syncInitial() async {
    _setState(
      state.copyWith(
        isInitialLoading: true,
        isLoadingMore: false,
        clearErrorMessage: true,
        clearLoadMoreErrorMessage: true,
      ),
    );

    try {
      final result = await _getMyHistoryUseCase(
        filter: AttendanceHistoryFilter(
          pageNumber: 1,
          pageSize: _defaultPageSize,
        ),
      );

      _setState(
        state.copyWith(
          items: _sortNewestFirst(result.items),
          totalCount: result.totalCount,
          currentPage: result.pageNumber,
          pageSize: result.pageSize,
          totalPages: result.totalPages,
          hasPreviousPage: result.hasPreviousPage,
          hasNextPage: result.hasNextPage,
          isInitialLoading: false,
          isLoadingMore: false,
          clearErrorMessage: true,
          clearLoadMoreErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          errorMessage: AppErrorUiMapper.message(
            error,
            operation: 'tải lịch sử điểm danh',
          ),
          clearLoadMoreErrorMessage: true,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          errorMessage: AppErrorUiMapper.exceptionMessage(
            operation: 'tải lịch sử điểm danh',
          ),
          clearLoadMoreErrorMessage: true,
        ),
      );
    }
  }

  Future<void> refresh() => syncInitial();

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    _setState(
      state.copyWith(isLoadingMore: true, clearLoadMoreErrorMessage: true),
    );

    try {
      final result = await _getMyHistoryUseCase(
        filter: AttendanceHistoryFilter(
          pageNumber: state.currentPage + 1,
          pageSize: state.pageSize,
        ),
      );
      final merged = <AttendanceHistoryItem>[...state.items, ...result.items];
      _setState(
        state.copyWith(
          items: _sortNewestFirst(merged),
          totalCount: result.totalCount,
          currentPage: result.pageNumber,
          pageSize: result.pageSize,
          totalPages: result.totalPages,
          hasPreviousPage: result.hasPreviousPage,
          hasNextPage: result.hasNextPage,
          isLoadingMore: false,
          clearLoadMoreErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isLoadingMore: false,
          loadMoreErrorMessage: AppErrorUiMapper.message(
            error,
            operation: 'tải thêm lịch sử điểm danh',
          ),
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          isLoadingMore: false,
          loadMoreErrorMessage: AppErrorUiMapper.exceptionMessage(
            operation: 'tải thêm lịch sử điểm danh',
          ),
        ),
      );
    }
  }

  void clearLoadMoreError() {
    if (state.loadMoreErrorMessage == null) {
      return;
    }
    _setState(state.copyWith(clearLoadMoreErrorMessage: true));
  }

  List<AttendanceHistoryItem> _sortNewestFirst(
    List<AttendanceHistoryItem> items,
  ) {
    final sorted = List<AttendanceHistoryItem>.from(items)
      ..sort((a, b) {
        final aTime = a.checkInTime?.millisecondsSinceEpoch ?? 0;
        final bTime = b.checkInTime?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
    return List<AttendanceHistoryItem>.unmodifiable(sorted);
  }

  void _setState(AttendanceHistoryState nextState) {
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
