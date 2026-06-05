import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../domain/usecases/events/get_home_event_preview_usecase.dart';
import '../../../../shared/mappers/app_error_ui_mapper.dart';
import 'home_event_preview_state.dart';

class HomeEventPreviewNotifier extends StateNotifier<HomeEventPreviewState> {
  HomeEventPreviewNotifier({
    required GetHomeEventPreviewUseCase getHomeEventPreviewUseCase,
  }) : _getHomeEventPreviewUseCase = getHomeEventPreviewUseCase,
       super(const HomeEventPreviewState());

  final GetHomeEventPreviewUseCase _getHomeEventPreviewUseCase;
  bool _isDisposed = false;

  Future<void> loadPreview() async {
    _setState(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );
    try {
      final items = await _getHomeEventPreviewUseCase();
      _setState(
        state.copyWith(
          items: items,
          isLoading: false,
          clearErrorMessage: true,
        ),
      );
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isLoading: false,
          errorMessage: AppErrorUiMapper.message(
            error,
            operation: 'tải danh sách sự kiện nổi bật',
          ),
        ),
      );
    } catch (_) {
      _setState(
        state.copyWith(
          isLoading: false,
          errorMessage: AppErrorUiMapper.exceptionMessage(
            operation: 'tải danh sách sự kiện nổi bật',
          ),
        ),
      );
    }
  }

  void _setState(HomeEventPreviewState nextState) {
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
