enum AuthBootstrapUiStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({
    this.bootstrapStatus = AuthBootstrapUiStatus.initial,
    this.isSubmitting = false,
    this.obscurePassword = true,
    this.errorMessage,
    this.codeBackendError,
    this.passwordBackendError,
    this.loginCooldownSeconds = 0,
    this.loginRateLimitBackendMessage,
    this.shouldNavigateToHome = false,
    this.shouldPromptNotificationPermissionSettings = false,
    this.handledInitialNotificationNavigation = false,
  });

  final AuthBootstrapUiStatus bootstrapStatus;
  final bool isSubmitting;
  final bool obscurePassword;
  final String? errorMessage;
  final String? codeBackendError;
  final String? passwordBackendError;
  final int loginCooldownSeconds;
  final String? loginRateLimitBackendMessage;
  final bool shouldNavigateToHome;
  final bool shouldPromptNotificationPermissionSettings;
  final bool handledInitialNotificationNavigation;

  bool get isLoginRateLimited => loginCooldownSeconds > 0;

  AuthState copyWith({
    AuthBootstrapUiStatus? bootstrapStatus,
    bool? isSubmitting,
    bool? obscurePassword,
    String? errorMessage,
    String? codeBackendError,
    String? passwordBackendError,
    int? loginCooldownSeconds,
    String? loginRateLimitBackendMessage,
    bool? shouldNavigateToHome,
    bool? shouldPromptNotificationPermissionSettings,
    bool? handledInitialNotificationNavigation,
    bool clearErrorMessage = false,
    bool clearBackendFieldErrors = false,
    bool clearCodeBackendError = false,
    bool clearPasswordBackendError = false,
    bool clearLoginRateLimitBackendMessage = false,
    bool clearNavigationSignal = false,
    bool clearNotificationPermissionPromptSignal = false,
    bool clearHandledInitialNotificationNavigation = false,
  }) {
    return AuthState(
      bootstrapStatus: bootstrapStatus ?? this.bootstrapStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      codeBackendError: clearBackendFieldErrors
          ? null
          : (clearCodeBackendError
                ? null
                : (codeBackendError ?? this.codeBackendError)),
      passwordBackendError: clearBackendFieldErrors
          ? null
          : (clearPasswordBackendError
                ? null
                : (passwordBackendError ?? this.passwordBackendError)),
      loginCooldownSeconds: loginCooldownSeconds ?? this.loginCooldownSeconds,
      loginRateLimitBackendMessage: clearLoginRateLimitBackendMessage
          ? null
          : (loginRateLimitBackendMessage ?? this.loginRateLimitBackendMessage),
      shouldNavigateToHome: clearNavigationSignal
          ? false
          : (shouldNavigateToHome ?? this.shouldNavigateToHome),
      shouldPromptNotificationPermissionSettings:
          clearNotificationPermissionPromptSignal
          ? false
          : (shouldPromptNotificationPermissionSettings ??
                this.shouldPromptNotificationPermissionSettings),
      handledInitialNotificationNavigation:
          clearHandledInitialNotificationNavigation
          ? false
          : (handledInitialNotificationNavigation ??
                this.handledInitialNotificationNavigation),
    );
  }
}


