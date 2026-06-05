import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/error/error_presenter.dart';
import '../../../../core/network/retry_policy/rate_limit_policy.dart';
import '../../../../domain/usecases/auth/login_usecase.dart';
import '../../../shared/forms/backend_field_error_picker.dart';
import 'auth_state.dart';

typedef AuthenticatedTokenSync = Future<bool> Function();
typedef ConsumeNotificationPermissionDeniedHint = bool Function();
typedef AuthBootstrapLoader = Future<AuthBootstrapUiStatus> Function();

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required LoginUseCase loginUseCase,
    AuthenticatedTokenSync? onAuthenticatedTokenSync,
    ConsumeNotificationPermissionDeniedHint?
    consumeNotificationPermissionDeniedHint,
  }) : _loginUseCase = loginUseCase,
       _onAuthenticatedTokenSync =
           onAuthenticatedTokenSync ?? _defaultAuthenticatedTokenSync,
       _consumeNotificationPermissionDeniedHint =
           consumeNotificationPermissionDeniedHint ??
           _defaultConsumeNotificationPermissionDeniedHint,
       super(const AuthState());

  final LoginUseCase _loginUseCase;
  final AuthenticatedTokenSync _onAuthenticatedTokenSync;
  final ConsumeNotificationPermissionDeniedHint
  _consumeNotificationPermissionDeniedHint;

  Timer? _loginCooldownTimer;
  bool _isDisposed = false;

  void toggleObscurePassword() {
    _updateState(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  void setBootstrapChecking() {
    _updateState(
      state.copyWith(
        bootstrapStatus: AuthBootstrapUiStatus.checking,
        clearErrorMessage: true,
      ),
    );
  }

  void setBootstrapStatus(AuthBootstrapUiStatus status) {
    _updateState(state.copyWith(bootstrapStatus: status));
  }

  Future<void> bootstrap({required AuthBootstrapLoader loadStatus}) async {
    setBootstrapChecking();
    try {
      final status = await loadStatus();
      _updateState(state.copyWith(bootstrapStatus: status));
    } catch (_) {
      _updateState(
        state.copyWith(bootstrapStatus: AuthBootstrapUiStatus.unauthenticated),
      );
    }
  }

  Future<void> submitLogin({
    required String code,
    required String password,
    AuthenticatedTokenSync? onAuthenticatedTokenSync,
    ConsumeNotificationPermissionDeniedHint?
    consumeNotificationPermissionDeniedHint,
  }) async {
    if (state.isSubmitting || state.isLoginRateLimited) {
      return;
    }

    _clearPostAuthSignals();
    _updateState(
      state.copyWith(
        isSubmitting: true,
        clearErrorMessage: true,
        clearBackendFieldErrors: true,
      ),
    );

    try {
      await _loginUseCase(
        code: code.trim(),
        password: password,
      );

      await resolvePostAuthentication(
        onAuthenticatedTokenSync: onAuthenticatedTokenSync,
        consumeNotificationPermissionDeniedHint:
            consumeNotificationPermissionDeniedHint,
      );
    } on AppError catch (error) {
      if (error.statusCode == 429) {
        _startLoginCooldown(backendMessage: error.message);
        return;
      }

      final codeError = BackendFieldErrorPicker.first(
        error,
        const <String>['code', 'Code', 'student_code'],
      );
      final passwordError = BackendFieldErrorPicker.first(error, const <String>[
        'password',
        'Password',
      ]);

      if (codeError != null || passwordError != null) {
        _updateState(
          state.copyWith(
            codeBackendError: codeError,
            passwordBackendError: passwordError,
            clearErrorMessage: true,
          ),
        );
      } else {
        _updateState(
          state.copyWith(errorMessage: _mapLoginErrorMessage(error.statusCode)),
        );
      }
    } finally {
      if (state.isSubmitting) {
        _updateState(state.copyWith(isSubmitting: false));
      }
    }
  }

  Future<void> resolvePostAuthentication({
    AuthenticatedTokenSync? onAuthenticatedTokenSync,
    ConsumeNotificationPermissionDeniedHint?
    consumeNotificationPermissionDeniedHint,
  }) async {
    _clearPostAuthSignals();

    var handledInitialNotificationNavigation = false;
    try {
      handledInitialNotificationNavigation =
          await (onAuthenticatedTokenSync ?? _onAuthenticatedTokenSync)();
    } catch (_) {
      // Ignore push registration error in auth flow.
    }

    if (handledInitialNotificationNavigation) {
      _updateState(
        state.copyWith(
          handledInitialNotificationNavigation: true,
          shouldNavigateToHome: false,
          shouldPromptNotificationPermissionSettings: false,
        ),
      );
      return;
    }

    final shouldPromptPermissionSettings =
        (consumeNotificationPermissionDeniedHint ??
            _consumeNotificationPermissionDeniedHint)();

    _updateState(
      state.copyWith(
        shouldPromptNotificationPermissionSettings:
            shouldPromptPermissionSettings,
        shouldNavigateToHome: true,
        handledInitialNotificationNavigation: false,
      ),
    );
  }

  void consumeNavigateToHomeSignal() {
    if (!state.shouldNavigateToHome) {
      return;
    }
    _updateState(state.copyWith(clearNavigationSignal: true));
  }

  void consumeNotificationPermissionPromptSignal() {
    if (!state.shouldPromptNotificationPermissionSettings) {
      return;
    }
    _updateState(
      state.copyWith(clearNotificationPermissionPromptSignal: true),
    );
  }

  void clearError() {
    _updateState(state.copyWith(clearErrorMessage: true));
  }

  void clearFieldErrors() {
    _updateState(state.copyWith(clearBackendFieldErrors: true));
  }

  void clearCodeBackendError() {
    if (state.codeBackendError == null) {
      return;
    }
    _updateState(state.copyWith(clearCodeBackendError: true));
  }

  void clearPasswordBackendError() {
    if (state.passwordBackendError == null) {
      return;
    }
    _updateState(state.copyWith(clearPasswordBackendError: true));
  }

  void _startLoginCooldown({String? backendMessage}) {
    final duration = RateLimitPolicy.cooldownFor(SensitiveApiAction.login);
    _loginCooldownTimer?.cancel();

    _updateState(
      state.copyWith(
        loginCooldownSeconds: duration.inSeconds,
        loginRateLimitBackendMessage: backendMessage,
        errorMessage: _mapLoginErrorMessage(
          429,
          cooldownSeconds: duration.inSeconds,
          backendMessage: backendMessage,
        ),
      ),
    );

    _loginCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      final nextSeconds = state.loginCooldownSeconds - 1;
      if (nextSeconds > 0) {
        _updateState(
          state.copyWith(
            loginCooldownSeconds: nextSeconds,
            errorMessage: _mapLoginErrorMessage(
              429,
              cooldownSeconds: nextSeconds,
              backendMessage: state.loginRateLimitBackendMessage,
            ),
          ),
        );
        return;
      }

      timer.cancel();
      _updateState(
        state.copyWith(
          loginCooldownSeconds: 0,
          clearErrorMessage: true,
          clearLoginRateLimitBackendMessage: true,
        ),
      );
    });
  }

  String _mapLoginErrorMessage(
    int? statusCode, {
    int? cooldownSeconds,
    String? backendMessage,
  }) {
    if (statusCode == 429) {
      if (cooldownSeconds != null && cooldownSeconds > 0) {
        return RateLimitPolicy.cooldownMessage(
          seconds: cooldownSeconds,
          backendMessage: backendMessage,
        );
      }
      return ErrorPresenter.presentStatusCode(429).message;
    }

    if (statusCode == 401) {
      // Keep credential-specific wording for login UX.
      return 'Sai mã sinh viên hoặc mật khẩu.';
    }

    return ErrorPresenter.presentStatusCode(statusCode).message;
  }

  void _updateState(AuthState nextState) {
    if (_isDisposed) {
      return;
    }
    state = nextState;
  }

  void _clearPostAuthSignals() {
    _updateState(
      state.copyWith(
        clearNavigationSignal: true,
        clearNotificationPermissionPromptSignal: true,
        clearHandledInitialNotificationNavigation: true,
      ),
    );
  }

  static Future<bool> _defaultAuthenticatedTokenSync() async {
    return false;
  }

  static bool _defaultConsumeNotificationPermissionDeniedHint() {
    return false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loginCooldownTimer?.cancel();
    super.dispose();
  }
}



