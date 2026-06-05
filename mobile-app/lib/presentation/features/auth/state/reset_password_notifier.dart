import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/error_presenter.dart';
import '../../../../domain/usecases/auth/reset_password_usecase.dart';
import 'reset_password_state.dart';

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  ResetPasswordNotifier({required ResetPasswordUseCase resetPasswordUseCase})
    : _resetPasswordUseCase = resetPasswordUseCase,
      super(const ResetPasswordState());

  final ResetPasswordUseCase _resetPasswordUseCase;
  bool _isDisposed = false;

  void toggleObscurePassword() {
    _updateState(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> submit({
    required String verificationTicket,
    required String newPassword,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    _updateState(
      state.copyWith(
        isSubmitting: true,
        clearMessage: true,
        isSuccess: false,
        requiresVerificationTicketRecovery: false,
      ),
    );

    try {
      final message = await _resetPasswordUseCase(
        verificationTicket: verificationTicket.trim(),
        newPassword: newPassword,
      );

      _updateState(
        state.copyWith(
          message: message,
          isSuccess: true,
          requiresVerificationTicketRecovery: false,
        ),
      );
    } on AppError catch (error) {
      final presented = ErrorPresenter.presentAppError(
        error,
        operation: 'đặt lại mật khẩu',
      );

      _updateState(
        state.copyWith(
          message: presented.message,
          isSuccess: false,
          requiresVerificationTicketRecovery:
              _requiresVerificationTicketRecovery(error),
        ),
      );
    } finally {
      _updateState(state.copyWith(isSubmitting: false));
    }
  }

  bool _requiresVerificationTicketRecovery(AppError error) {
    if (error.statusCode != 400) {
      return false;
    }

    final normalizedMessage = error.message.trim().toLowerCase();
    final accentStrippedMessage = _stripVietnameseAccents(normalizedMessage);
    if (normalizedMessage.isEmpty ||
        !normalizedMessage.contains('verification ticket')) {
      return false;
    }

    return normalizedMessage.contains('không hợp lệ') ||
        normalizedMessage.contains('hết hạn') ||
        accentStrippedMessage.contains(
          _stripVietnameseAccents('không hợp lệ'),
        ) ||
        accentStrippedMessage.contains(_stripVietnameseAccents('hết hạn')) ||
        normalizedMessage.contains('invalid') ||
        normalizedMessage.contains('expired');
  }

  String _stripVietnameseAccents(String value) {
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'đ': 'd',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
    };

    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      buffer.write(replacements[character] ?? character);
    }
    return buffer.toString();
  }

  void _updateState(ResetPasswordState nextState) {
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
