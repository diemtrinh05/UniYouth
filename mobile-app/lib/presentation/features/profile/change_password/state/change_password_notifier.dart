import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../core/error/error_presenter.dart';
import '../../../../../../domain/usecases/profile/change_password_usecase.dart';
import '../../../../shared/forms/backend_field_error_picker.dart';
import 'change_password_state.dart';

enum ChangePasswordBackendField {
  currentPassword,
  newPassword,
  confirmNewPassword,
}

class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  ChangePasswordNotifier({required ChangePasswordUseCase changePasswordUseCase})
    : _changePasswordUseCase = changePasswordUseCase,
      super(const ChangePasswordState());

  final ChangePasswordUseCase _changePasswordUseCase;
  bool _isDisposed = false;

  void toggleCurrentVisibility() {
    _setState(state.copyWith(obscureCurrent: !state.obscureCurrent));
  }

  void toggleNewVisibility() {
    _setState(state.copyWith(obscureNew: !state.obscureNew));
  }

  void toggleConfirmVisibility() {
    _setState(state.copyWith(obscureConfirm: !state.obscureConfirm));
  }

  void updatePasswordStrength(String password) {
    var strength = 0;
    if (password.length >= 8) {
      strength++;
    }
    if (password.contains(RegExp(r'[A-Z]'))) {
      strength++;
    }
    if (password.contains(RegExp(r'[0-9]'))) {
      strength++;
    }
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      strength++;
    }

    if (state.passwordStrength == strength) {
      return;
    }
    _setState(state.copyWith(passwordStrength: strength));
  }

  void clearBackendError(ChangePasswordBackendField field) {
    switch (field) {
      case ChangePasswordBackendField.currentPassword:
        _setState(state.copyWith(clearCurrentPasswordBackendError: true));
        break;
      case ChangePasswordBackendField.newPassword:
        _setState(state.copyWith(clearNewPasswordBackendError: true));
        break;
      case ChangePasswordBackendField.confirmNewPassword:
        _setState(state.copyWith(clearConfirmNewPasswordBackendError: true));
        break;
    }
  }

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    _setState(
      state.copyWith(
        isSubmitting: true,
        clearMessage: true,
        isSuccess: false,
        clearCurrentPasswordBackendError: true,
        clearNewPasswordBackendError: true,
        clearConfirmNewPasswordBackendError: true,
      ),
    );

    var didSucceed = false;
    try {
      final result = await _changePasswordUseCase(
        input: ChangePasswordInput(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmNewPassword: confirmNewPassword,
        ),
      );

      _setState(
        state.copyWith(
          message: _pickBackendMessage(result),
          isSuccess: result.success,
        ),
      );
      didSucceed = result.success;
    } on AppError catch (error) {
      final currentPasswordError = BackendFieldErrorPicker.first(
        error,
        const <String>['currentPassword', 'CurrentPassword'],
      );
      final newPasswordError = BackendFieldErrorPicker.first(
        error,
        const <String>['newPassword', 'NewPassword'],
      );
      final confirmNewPasswordError = BackendFieldErrorPicker.first(
        error,
        const <String>['confirmNewPassword', 'ConfirmNewPassword'],
      );

      final hasAnyFieldError =
          currentPasswordError != null ||
          newPasswordError != null ||
          confirmNewPasswordError != null;

      _setState(
        state.copyWith(
          currentPasswordBackendError: currentPasswordError,
          newPasswordBackendError: newPasswordError,
          confirmNewPasswordBackendError: confirmNewPasswordError,
          message: hasAnyFieldError
              ? null
              : ErrorPresenter.presentAppError(
                  error,
                  operation: 'đổi mật khẩu',
                ).message,
          isSuccess: false,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          message: ErrorPresenter.presentException(
            operation: 'đổi mật khẩu',
          ).message,
          isSuccess: false,
        ),
      );
    } finally {
      _setState(state.copyWith(isSubmitting: false));
    }

    return didSucceed;
  }

  String _pickBackendMessage(ChangePasswordResult result) {
    final dataMessage = (result.message ?? '').trim();
    if (dataMessage.isNotEmpty) {
      return dataMessage;
    }
    final additionalInfo = (result.additionalInfo ?? '').trim();
    if (additionalInfo.isNotEmpty) {
      return additionalInfo;
    }
    return 'Thao tác thành công';
  }

  void _setState(ChangePasswordState nextState) {
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
