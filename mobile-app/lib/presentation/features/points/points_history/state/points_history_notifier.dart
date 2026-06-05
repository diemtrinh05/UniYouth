import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../core/error/error_presenter.dart';
import '../../../../../../domain/usecases/points/get_points_history_usecase.dart';
import 'points_history_state.dart';

class PointsHistoryNotifier extends StateNotifier<PointsHistoryState> {
  PointsHistoryNotifier({
    required GetPointsHistoryUseCase getPointsHistoryUseCase,
    int defaultPageSize = 20,
  }) : _getPointsHistoryUseCase = getPointsHistoryUseCase,
       _defaultPageSize = defaultPageSize,
       super(PointsHistoryState(pageSize: defaultPageSize));

  final GetPointsHistoryUseCase _getPointsHistoryUseCase;
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
      final result = await _getPointsHistoryUseCase(
        filter: PointsHistoryFilter(pageNumber: 1, pageSize: _defaultPageSize),
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
          errorMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'tải lịch sử điểm',
          ).message,
          clearLoadMoreErrorMessage: true,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          isInitialLoading: false,
          isLoadingMore: false,
          errorMessage: ErrorPresenter.presentException(
            operation: 'tải lịch sử điểm',
          ).message,
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
      final result = await _getPointsHistoryUseCase(
        filter: PointsHistoryFilter(
          pageNumber: state.currentPage + 1,
          pageSize: state.pageSize,
        ),
      );

      final merged = <PointsHistoryItem>[...state.items, ...result.items];
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
          loadMoreErrorMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'tải thêm lịch sử điểm',
          ).message,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          isLoadingMore: false,
          loadMoreErrorMessage: ErrorPresenter.presentException(
            operation: 'tải thêm lịch sử điểm',
          ).message,
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

  List<PointsHistoryItem> _sortNewestFirst(List<PointsHistoryItem> items) {
    final sorted = List<PointsHistoryItem>.from(items)
      ..sort((a, b) {
        final aTime =
            a.createdDate?.millisecondsSinceEpoch ??
            a.eventStartTime?.millisecondsSinceEpoch ??
            0;
        final bTime =
            b.createdDate?.millisecondsSinceEpoch ??
            b.eventStartTime?.millisecondsSinceEpoch ??
            0;
        return bTime.compareTo(aTime);
      });
    return List<PointsHistoryItem>.unmodifiable(sorted);
  }

  void _setState(PointsHistoryState nextState) {
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
