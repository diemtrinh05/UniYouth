class ChangePasswordState {
  const ChangePasswordState({
    this.isSubmitting = false,
    this.obscureCurrent = true,
    this.obscureNew = true,
    this.obscureConfirm = true,
    this.message,
    this.isSuccess = false,
    this.currentPasswordBackendError,
    this.newPasswordBackendError,
    this.confirmNewPasswordBackendError,
    this.passwordStrength = 0,
  });

  final bool isSubmitting;
  final bool obscureCurrent;
  final bool obscureNew;
  final bool obscureConfirm;
  final String? message;
  final bool isSuccess;
  final String? currentPasswordBackendError;
  final String? newPasswordBackendError;
  final String? confirmNewPasswordBackendError;
  final int passwordStrength;

  ChangePasswordState copyWith({
    bool? isSubmitting,
    bool? obscureCurrent,
    bool? obscureNew,
    bool? obscureConfirm,
    String? message,
    bool clearMessage = false,
    bool? isSuccess,
    String? currentPasswordBackendError,
    bool clearCurrentPasswordBackendError = false,
    String? newPasswordBackendError,
    bool clearNewPasswordBackendError = false,
    String? confirmNewPasswordBackendError,
    bool clearConfirmNewPasswordBackendError = false,
    int? passwordStrength,
  }) {
    return ChangePasswordState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      obscureCurrent: obscureCurrent ?? this.obscureCurrent,
      obscureNew: obscureNew ?? this.obscureNew,
      obscureConfirm: obscureConfirm ?? this.obscureConfirm,
      message: clearMessage ? null : (message ?? this.message),
      isSuccess: isSuccess ?? this.isSuccess,
      currentPasswordBackendError: clearCurrentPasswordBackendError
          ? null
          : (currentPasswordBackendError ?? this.currentPasswordBackendError),
      newPasswordBackendError: clearNewPasswordBackendError
          ? null
          : (newPasswordBackendError ?? this.newPasswordBackendError),
      confirmNewPasswordBackendError: clearConfirmNewPasswordBackendError
          ? null
          : (confirmNewPasswordBackendError ??
                this.confirmNewPasswordBackendError),
      passwordStrength: passwordStrength ?? this.passwordStrength,
    );
  }
}
