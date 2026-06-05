import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/error_presenter.dart';
import '../../../../domain/usecases/auth/forgot_password_usecase.dart';
import 'forgot_password_state.dart';

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier({
    required ForgotPasswordUseCase forgotPasswordUseCase,
  }) : _forgotPasswordUseCase = forgotPasswordUseCase,
       super(const ForgotPasswordState());

  final ForgotPasswordUseCase _forgotPasswordUseCase;
  bool _isDisposed = false;

  Future<void> submit({required String account}) async {
    if (state.isSubmitting) {
      return;
    }

    _updateState(
      state.copyWith(
        isSubmitting: true,
        clearMessage: true,
        isSuccess: false,
      ),
    );

    try {
      final message = await _forgotPasswordUseCase(account: account.trim());
      _updateState(
        state.copyWith(
          message: message,
          isSuccess: true,
        ),
      );
    } on AppError catch (error) {
      final presented = ErrorPresenter.presentAppError(
        error,
        operation: 'gửi yêu cầu quên mật khẩu',
      );
      _updateState(
        state.copyWith(
          message: presented.message,
          isSuccess: false,
        ),
      );
    } finally {
      _updateState(state.copyWith(isSubmitting: false));
    }
  }

  void _updateState(ForgotPasswordState nextState) {
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
