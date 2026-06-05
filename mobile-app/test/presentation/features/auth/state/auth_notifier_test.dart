import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/domain/usecases/auth/login_usecase.dart';
import 'package:uniyouth_app/presentation/features/auth/state/auth_notifier.dart';
import 'package:uniyouth_app/presentation/features/auth/state/auth_state.dart';

void main() {
  group('AuthNotifier', () {
    test(
      'submitLogin trims code and sets navigate signal on success',
      () async {
        final repository = _FakeLoginRepository();
        final notifier = AuthNotifier(
          loginUseCase: LoginUseCase(repository: repository),
          onAuthenticatedTokenSync: () async => false,
          consumeNotificationPermissionDeniedHint: () => false,
        );
        addTearDown(notifier.dispose);

        await notifier.submitLogin(
          code: '  sv001  ',
          password: 'secret',
        );

        expect(repository.loginCallCount, 1);
        expect(repository.lastStudentCode, 'sv001');
        expect(repository.lastPassword, 'secret');
        expect(notifier.state.isSubmitting, isFalse);
        expect(notifier.state.shouldNavigateToHome, isTrue);
        expect(notifier.state.errorMessage, isNull);
      },
    );

    test('submitLogin sets cooldown state when receive 429', () async {
      final repository = _FakeLoginRepository()
        ..onLogin = ({required code, required password}) async {
          throw const AppError(
            type: AppErrorType.tooManyRequests,
            statusCode: 429,
            message: 'Too many requests',
          );
        };
      final notifier = AuthNotifier(
        loginUseCase: LoginUseCase(repository: repository),
      );
      addTearDown(notifier.dispose);

      await notifier.submitLogin(code: 'sv001', password: 'secret');

      expect(notifier.state.isSubmitting, isFalse);
      expect(notifier.state.isLoginRateLimited, isTrue);
      expect(notifier.state.loginCooldownSeconds, greaterThan(0));
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('submitLogin maps backend field errors', () async {
      final repository = _FakeLoginRepository()
        ..onLogin = ({required code, required password}) async {
          throw const AppError(
            type: AppErrorType.badRequest,
            message: 'Validation failed',
            fieldErrors: <String, List<String>>{
              'code': <String>['Student code is invalid'],
              'password': <String>['Password is invalid'],
            },
          );
        };
      final notifier = AuthNotifier(
        loginUseCase: LoginUseCase(repository: repository),
      );
      addTearDown(notifier.dispose);

      await notifier.submitLogin(code: 'sv001', password: 'secret');

      expect(notifier.state.codeBackendError, 'Student code is invalid');
      expect(notifier.state.passwordBackendError, 'Password is invalid');
      expect(notifier.state.errorMessage, isNull);
    });

    test(
      'bootstrap falls back to unauthenticated when loader throws',
      () async {
        final notifier = AuthNotifier(
          loginUseCase: LoginUseCase(repository: _FakeLoginRepository()),
        );
        addTearDown(notifier.dispose);

        await notifier.bootstrap(
          loadStatus: () async => throw Exception('bootstrap failed'),
        );

        expect(
          notifier.state.bootstrapStatus,
          AuthBootstrapUiStatus.unauthenticated,
        );
      },
    );

    test(
      'resolvePostAuthentication handles initial notification navigation',
      () async {
        final notifier = AuthNotifier(
          loginUseCase: LoginUseCase(repository: _FakeLoginRepository()),
        );
        addTearDown(notifier.dispose);

        await notifier.resolvePostAuthentication(
          onAuthenticatedTokenSync: () async => true,
          consumeNotificationPermissionDeniedHint: () => true,
        );

        expect(notifier.state.handledInitialNotificationNavigation, isTrue);
        expect(notifier.state.shouldNavigateToHome, isFalse);
        expect(
          notifier.state.shouldPromptNotificationPermissionSettings,
          isFalse,
        );
      },
    );
  });
}

class _FakeLoginRepository implements LoginRepository {
  int loginCallCount = 0;
  String? lastStudentCode;
  String? lastPassword;

  Future<void> Function({
    required String code,
    required String password,
  })?
  onLogin;

  @override
  Future<void> login({
    required String code,
    required String password,
  }) async {
    loginCallCount += 1;
    lastStudentCode = code;
    lastPassword = password;

    final override = onLogin;
    if (override != null) {
      await override(code: code, password: password);
    }
  }
}


