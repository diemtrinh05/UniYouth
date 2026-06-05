class ResetPasswordState {
  const ResetPasswordState({
    this.isSubmitting = false,
    this.obscurePassword = true,
    this.message,
    this.isSuccess = false,
    this.requiresVerificationTicketRecovery = false,
  });

  final bool isSubmitting;
  final bool obscurePassword;
  final String? message;
  final bool isSuccess;
  final bool requiresVerificationTicketRecovery;

  ResetPasswordState copyWith({
    bool? isSubmitting,
    bool? obscurePassword,
    String? message,
    bool? isSuccess,
    bool? requiresVerificationTicketRecovery,
    bool clearMessage = false,
  }) {
    return ResetPasswordState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      message: clearMessage ? null : (message ?? this.message),
      isSuccess: isSuccess ?? this.isSuccess,
      requiresVerificationTicketRecovery:
          requiresVerificationTicketRecovery ??
          this.requiresVerificationTicketRecovery,
    );
  }
}
