class ForgotPasswordState {
  const ForgotPasswordState({
    this.isSubmitting = false,
    this.message,
    this.isSuccess = false,
  });

  final bool isSubmitting;
  final String? message;
  final bool isSuccess;

  ForgotPasswordState copyWith({
    bool? isSubmitting,
    String? message,
    bool? isSuccess,
    bool clearMessage = false,
  }) {
    return ForgotPasswordState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: clearMessage ? null : (message ?? this.message),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}
