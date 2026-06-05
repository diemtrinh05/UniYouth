import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/domain/usecases/profile/change_password_usecase.dart';
import 'package:uniyouth_app/presentation/features/profile/change_password/state/change_password_notifier.dart';

void main() {
  group('ChangePasswordNotifier', () {
    test(
      'submit returns true and sets success state on valid response',
      () async {
        final repository = _FakeChangePasswordRepository()
          ..onChangePassword = ({required input}) async {
            return const ChangePasswordResult(
              success: true,
              message: 'Đổi mật khẩu thành công',
              additionalInfo: null,
            );
          };
        final notifier = ChangePasswordNotifier(
          changePasswordUseCase: ChangePasswordUseCase(repository: repository),
        );
        addTearDown(notifier.dispose);

        final didSucceed = await notifier.submit(
          currentPassword: 'old-pass',
          newPassword: 'NewPass@123',
          confirmNewPassword: 'NewPass@123',
        );

        expect(didSucceed, isTrue);
        expect(repository.callCount, 1);
        expect(repository.lastInput?.currentPassword, 'old-pass');
        expect(notifier.state.isSuccess, isTrue);
        expect(notifier.state.message, 'Đổi mật khẩu thành công');
        expect(notifier.state.isSubmitting, isFalse);
      },
    );

    test(
      'submit maps backend field errors when AppError has fieldErrors',
      () async {
        final repository = _FakeChangePasswordRepository()
          ..onChangePassword = ({required input}) async {
            throw const AppError(
              type: AppErrorType.badRequest,
              message: 'Validation failed',
              fieldErrors: <String, List<String>>{
                'currentPassword': <String>['Mật khẩu hiện tại không đúng'],
                'newPassword': <String>['Mật khẩu mới quá yếu'],
              },
            );
          };
        final notifier = ChangePasswordNotifier(
          changePasswordUseCase: ChangePasswordUseCase(repository: repository),
        );
        addTearDown(notifier.dispose);

        final didSucceed = await notifier.submit(
          currentPassword: 'wrong',
          newPassword: '123',
          confirmNewPassword: '123',
        );

        expect(didSucceed, isFalse);
        expect(notifier.state.isSuccess, isFalse);
        expect(
          notifier.state.currentPasswordBackendError,
          'Mật khẩu hiện tại không đúng',
        );
        expect(notifier.state.newPasswordBackendError, 'Mật khẩu mới quá yếu');
        expect(notifier.state.message, isNull);
        expect(notifier.state.isSubmitting, isFalse);
      },
    );
  });
}

class _FakeChangePasswordRepository implements ChangePasswordRepository {
  int callCount = 0;
  ChangePasswordInput? lastInput;

  Future<ChangePasswordResult> Function({required ChangePasswordInput input})?
  onChangePassword;

  @override
  Future<ChangePasswordResult> changePassword({
    required ChangePasswordInput input,
  }) async {
    callCount += 1;
    lastInput = input;
    final override = onChangePassword;
    if (override != null) {
      return override(input: input);
    }
    return const ChangePasswordResult(
      success: true,
      message: 'OK',
      additionalInfo: null,
    );
  }
}
