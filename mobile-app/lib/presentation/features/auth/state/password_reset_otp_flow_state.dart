enum PasswordResetOtpFlowStep {
  enterEmail,
  enterOtp,
  resetPassword,
  completed,
}

class PasswordResetOtpFlowState {
  const PasswordResetOtpFlowState({
    this.step = PasswordResetOtpFlowStep.enterEmail,
    this.email,
    this.otpExpiresAt,
    this.resendAvailableAt,
    this.verificationTicket,
    this.verificationTicketExpiresAt,
    this.isSubmittingForgot = false,
    this.isSubmittingVerify = false,
    this.isSubmittingReset = false,
    this.message,
    this.errorMessage,
  });

  final PasswordResetOtpFlowStep step;
  final String? email;
  final DateTime? otpExpiresAt;
  final DateTime? resendAvailableAt;
  final String? verificationTicket;
  final DateTime? verificationTicketExpiresAt;
  final bool isSubmittingForgot;
  final bool isSubmittingVerify;
  final bool isSubmittingReset;
  final String? message;
  final String? errorMessage;

  bool get hasEmail => email != null && email!.trim().isNotEmpty;

  bool get hasVerificationTicket =>
      verificationTicket != null && verificationTicket!.trim().isNotEmpty;

  PasswordResetOtpFlowState copyWith({
    PasswordResetOtpFlowStep? step,
    String? email,
    DateTime? otpExpiresAt,
    DateTime? resendAvailableAt,
    String? verificationTicket,
    DateTime? verificationTicketExpiresAt,
    bool? isSubmittingForgot,
    bool? isSubmittingVerify,
    bool? isSubmittingReset,
    String? message,
    String? errorMessage,
    bool clearEmail = false,
    bool clearOtpTiming = false,
    bool clearVerificationTicket = false,
    bool clearMessage = false,
    bool clearErrorMessage = false,
  }) {
    return PasswordResetOtpFlowState(
      step: step ?? this.step,
      email: clearEmail ? null : (email ?? this.email),
      otpExpiresAt: clearOtpTiming ? null : (otpExpiresAt ?? this.otpExpiresAt),
      resendAvailableAt:
          clearOtpTiming ? null : (resendAvailableAt ?? this.resendAvailableAt),
      verificationTicket: clearVerificationTicket
          ? null
          : (verificationTicket ?? this.verificationTicket),
      verificationTicketExpiresAt: clearVerificationTicket
          ? null
          : (verificationTicketExpiresAt ?? this.verificationTicketExpiresAt),
      isSubmittingForgot: isSubmittingForgot ?? this.isSubmittingForgot,
      isSubmittingVerify: isSubmittingVerify ?? this.isSubmittingVerify,
      isSubmittingReset: isSubmittingReset ?? this.isSubmittingReset,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
