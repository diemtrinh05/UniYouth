import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../core/error/error_presenter.dart';
import '../../../../../../domain/usecases/points/get_my_points_usecase.dart';
import 'points_summary_state.dart';

class PointsSummaryNotifier extends StateNotifier<PointsSummaryState> {
  PointsSummaryNotifier({required GetMyPointsUseCase getMyPointsUseCase})
    : _getMyPointsUseCase = getMyPointsUseCase,
      super(const PointsSummaryState());

  final GetMyPointsUseCase _getMyPointsUseCase;
  bool _isDisposed = false;

  Future<void> syncInitial() async {
    _setState(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final result = await _getMyPointsUseCase();
      _setState(
        state.copyWith(
          summary: result,
          isLoading: false,
          clearErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      final presented = ErrorPresenter.presentAppError(
        error,
        operation: 'tải tổng quan điểm',
      );
      _setState(
        state.copyWith(isLoading: false, errorMessage: presented.message),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorPresenter.presentException(
            operation: 'tải tổng quan điểm',
          ).message,
        ),
      );
    }
  }

  Future<void> refresh() => syncInitial();

  void _setState(PointsSummaryState nextState) {
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
