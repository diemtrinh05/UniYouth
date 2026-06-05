import 'package:flutter_riverpod/legacy.dart';

import 'password_reset_otp_flow_state.dart';

class PasswordResetOtpFlowNotifier
    extends StateNotifier<PasswordResetOtpFlowState> {
  PasswordResetOtpFlowNotifier() : super(const PasswordResetOtpFlowState());

  bool _isDisposed = false;

  void updateEmail(String? email) {
    final normalizedEmail = email?.trim();
    _updateState(
      state.copyWith(
        email: normalizedEmail == null || normalizedEmail.isEmpty
            ? null
            : normalizedEmail,
      ),
    );
  }

  void beginOtpStep({
    required String email,
    DateTime? otpExpiresAt,
    DateTime? resendAvailableAt,
    String? message,
  }) {
    final normalizedEmail = email.trim();
    _updateState(
      state.copyWith(
        step: PasswordResetOtpFlowStep.enterOtp,
        email: normalizedEmail.isEmpty ? null : normalizedEmail,
        otpExpiresAt: otpExpiresAt,
        resendAvailableAt: resendAvailableAt,
        isSubmittingForgot: false,
        clearVerificationTicket: true,
        message: message,
        clearErrorMessage: true,
      ),
    );
  }

  void setOtpTiming({DateTime? otpExpiresAt, DateTime? resendAvailableAt}) {
    _updateState(
      state.copyWith(
        otpExpiresAt: otpExpiresAt,
        resendAvailableAt: resendAvailableAt,
      ),
    );
  }

  void setVerificationResult({
    required String verificationTicket,
    DateTime? verificationTicketExpiresAt,
    String? message,
  }) {
    final normalizedTicket = verificationTicket.trim();
    _updateState(
      state.copyWith(
        step: PasswordResetOtpFlowStep.resetPassword,
        verificationTicket: normalizedTicket.isEmpty ? null : normalizedTicket,
        verificationTicketExpiresAt: verificationTicketExpiresAt,
        isSubmittingVerify: false,
        message: message,
        clearErrorMessage: true,
      ),
    );
  }

  void markForgotSubmitting(bool isSubmitting) {
    _updateState(
      state.copyWith(
        isSubmittingForgot: isSubmitting,
        clearMessage: isSubmitting,
        clearErrorMessage: isSubmitting,
      ),
    );
  }

  void markVerifySubmitting(bool isSubmitting) {
    _updateState(
      state.copyWith(
        isSubmittingVerify: isSubmitting,
        clearMessage: isSubmitting,
        clearErrorMessage: isSubmitting,
      ),
    );
  }

  void markResetSubmitting(bool isSubmitting) {
    _updateState(
      state.copyWith(
        isSubmittingReset: isSubmitting,
        clearMessage: isSubmitting,
        clearErrorMessage: isSubmitting,
      ),
    );
  }

  void setMessage(String? message) {
    _updateState(
      state.copyWith(message: message?.trim(), clearErrorMessage: true),
    );
  }

  void setError(String? errorMessage) {
    _updateState(
      state.copyWith(errorMessage: errorMessage?.trim(), clearMessage: true),
    );
  }

  void clearFeedback() {
    _updateState(state.copyWith(clearMessage: true, clearErrorMessage: true));
  }

  void clearVerificationTicket() {
    _updateState(state.copyWith(clearVerificationTicket: true));
  }

  void backToEnterOtp({
    DateTime? otpExpiresAt,
    DateTime? resendAvailableAt,
    String? message,
  }) {
    _updateState(
      state.copyWith(
        step: PasswordResetOtpFlowStep.enterOtp,
        otpExpiresAt: otpExpiresAt ?? state.otpExpiresAt,
        resendAvailableAt: resendAvailableAt ?? state.resendAvailableAt,
        clearVerificationTicket: true,
        isSubmittingVerify: false,
        isSubmittingReset: false,
        message: message?.trim(),
        clearErrorMessage: true,
      ),
    );
  }

  void recoverFromInvalidVerificationTicket({String? message}) {
    _updateState(
      state.copyWith(
        step: PasswordResetOtpFlowStep.enterOtp,
        clearVerificationTicket: true,
        isSubmittingReset: false,
        message: message?.trim(),
        clearErrorMessage: true,
      ),
    );
  }

  void backToEnterEmail({bool preserveEmail = true}) {
    _updateState(
      state.copyWith(
        step: PasswordResetOtpFlowStep.enterEmail,
        clearEmail: !preserveEmail,
        clearOtpTiming: true,
        clearVerificationTicket: true,
        isSubmittingForgot: false,
        isSubmittingVerify: false,
        isSubmittingReset: false,
        clearMessage: true,
        clearErrorMessage: true,
      ),
    );
  }

  void completeFlow({String? message}) {
    _updateState(
      state.copyWith(
        step: PasswordResetOtpFlowStep.completed,
        isSubmittingForgot: false,
        isSubmittingVerify: false,
        isSubmittingReset: false,
        message: message?.trim(),
        clearErrorMessage: true,
      ),
    );
  }

  void clearFlow() {
    _updateState(const PasswordResetOtpFlowState());
  }

  void _updateState(PasswordResetOtpFlowState nextState) {
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
