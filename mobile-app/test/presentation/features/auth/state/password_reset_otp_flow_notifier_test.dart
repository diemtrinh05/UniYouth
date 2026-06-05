import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/presentation/features/auth/state/password_reset_otp_flow_notifier.dart';
import 'package:uniyouth_app/presentation/features/auth/state/password_reset_otp_flow_state.dart';

void main() {
  group('PasswordResetOtpFlowNotifier', () {
    test('starts at enterEmail with empty transient state', () {
      final notifier = PasswordResetOtpFlowNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state.step, PasswordResetOtpFlowStep.enterEmail);
      expect(notifier.state.email, isNull);
      expect(notifier.state.verificationTicket, isNull);
      expect(notifier.state.hasEmail, isFalse);
      expect(notifier.state.hasVerificationTicket, isFalse);
    });

    test(
      'beginOtpStep trims account, clears old ticket, and resets forgot loading',
      () {
        final notifier = PasswordResetOtpFlowNotifier();
        addTearDown(notifier.dispose);
        final otpExpiresAt = DateTime(2026, 3, 8, 10, 0, 0);
        final resendAvailableAt = DateTime(2026, 3, 8, 10, 0, 30);

        notifier
          ..markForgotSubmitting(true)
          ..setVerificationResult(
            verificationTicket: 'old-ticket',
            verificationTicketExpiresAt: DateTime(2026, 3, 8, 10, 5, 0),
          )
          ..setError('old error');

        notifier.beginOtpStep(
          email: '  SV2001  ',
          otpExpiresAt: otpExpiresAt,
          resendAvailableAt: resendAvailableAt,
          message: 'OTP sent',
        );

        expect(notifier.state.step, PasswordResetOtpFlowStep.enterOtp);
        expect(notifier.state.email, 'SV2001');
        expect(notifier.state.otpExpiresAt, otpExpiresAt);
        expect(notifier.state.resendAvailableAt, resendAvailableAt);
        expect(notifier.state.verificationTicket, isNull);
        expect(notifier.state.isSubmittingForgot, isFalse);
        expect(notifier.state.message, 'OTP sent');
        expect(notifier.state.errorMessage, isNull);
      },
    );

    test(
      'setVerificationResult moves flow to resetPassword and stores ticket only in memory',
      () {
        final notifier = PasswordResetOtpFlowNotifier();
        addTearDown(notifier.dispose);
        final ticketExpiresAt = DateTime(2026, 3, 8, 10, 15, 0);

        notifier
          ..beginOtpStep(email: 'SV2001')
          ..markVerifySubmitting(true)
          ..setError('OTP wrong');

        notifier.setVerificationResult(
          verificationTicket: '  verification-ticket  ',
          verificationTicketExpiresAt: ticketExpiresAt,
          message: 'OTP verified',
        );

        expect(notifier.state.step, PasswordResetOtpFlowStep.resetPassword);
        expect(notifier.state.verificationTicket, 'verification-ticket');
        expect(notifier.state.verificationTicketExpiresAt, ticketExpiresAt);
        expect(notifier.state.isSubmittingVerify, isFalse);
        expect(notifier.state.message, 'OTP verified');
        expect(notifier.state.errorMessage, isNull);
      },
    );

    test(
      'backToEnterOtp clears ticket and reset submitting while preserving email and timing',
      () {
        final notifier = PasswordResetOtpFlowNotifier();
        addTearDown(notifier.dispose);
        final otpExpiresAt = DateTime(2026, 3, 8, 10, 0, 0);
        final resendAvailableAt = DateTime(2026, 3, 8, 10, 0, 30);

        notifier
          ..beginOtpStep(
            email: 'SV2001',
            otpExpiresAt: otpExpiresAt,
            resendAvailableAt: resendAvailableAt,
          )
          ..setVerificationResult(
            verificationTicket: 'ticket',
            verificationTicketExpiresAt: DateTime(2026, 3, 8, 10, 5, 0),
          )
          ..markResetSubmitting(true);

        notifier.backToEnterOtp(message: 'Try again');

        expect(notifier.state.step, PasswordResetOtpFlowStep.enterOtp);
        expect(notifier.state.email, 'SV2001');
        expect(notifier.state.otpExpiresAt, otpExpiresAt);
        expect(notifier.state.resendAvailableAt, resendAvailableAt);
        expect(notifier.state.verificationTicket, isNull);
        expect(notifier.state.verificationTicketExpiresAt, isNull);
        expect(notifier.state.isSubmittingReset, isFalse);
        expect(notifier.state.message, 'Try again');
      },
    );

    test(
      'backToEnterEmail clears transient OTP/ticket state and can preserve email',
      () {
        final notifier = PasswordResetOtpFlowNotifier();
        addTearDown(notifier.dispose);

        notifier
          ..beginOtpStep(
            email: 'SV2001',
            otpExpiresAt: DateTime(2026, 3, 8, 10, 0, 0),
            resendAvailableAt: DateTime(2026, 3, 8, 10, 0, 30),
          )
          ..setVerificationResult(
            verificationTicket: 'ticket',
            verificationTicketExpiresAt: DateTime(2026, 3, 8, 10, 5, 0),
          )
          ..markForgotSubmitting(true)
          ..markVerifySubmitting(true)
          ..markResetSubmitting(true)
          ..setMessage('message')
          ..setError('error');

        notifier.backToEnterEmail(preserveEmail: true);

        expect(notifier.state.step, PasswordResetOtpFlowStep.enterEmail);
        expect(notifier.state.email, 'SV2001');
        expect(notifier.state.otpExpiresAt, isNull);
        expect(notifier.state.resendAvailableAt, isNull);
        expect(notifier.state.verificationTicket, isNull);
        expect(notifier.state.isSubmittingForgot, isFalse);
        expect(notifier.state.isSubmittingVerify, isFalse);
        expect(notifier.state.isSubmittingReset, isFalse);
        expect(notifier.state.message, isNull);
        expect(notifier.state.errorMessage, isNull);
      },
    );

    test('completeFlow marks completed and clearFlow resets entire state', () {
      final notifier = PasswordResetOtpFlowNotifier();
      addTearDown(notifier.dispose);

      notifier
        ..beginOtpStep(email: 'SV2001')
        ..setVerificationResult(
          verificationTicket: 'ticket',
          verificationTicketExpiresAt: DateTime(2026, 3, 8, 10, 5, 0),
        )
        ..completeFlow(message: 'Password reset success');

      expect(notifier.state.step, PasswordResetOtpFlowStep.completed);
      expect(notifier.state.message, 'Password reset success');
      expect(notifier.state.isSubmittingForgot, isFalse);
      expect(notifier.state.isSubmittingVerify, isFalse);
      expect(notifier.state.isSubmittingReset, isFalse);

      notifier.clearFlow();

      expect(notifier.state.step, PasswordResetOtpFlowStep.enterEmail);
      expect(notifier.state.email, isNull);
      expect(notifier.state.otpExpiresAt, isNull);
      expect(notifier.state.resendAvailableAt, isNull);
      expect(notifier.state.verificationTicket, isNull);
      expect(notifier.state.message, isNull);
      expect(notifier.state.errorMessage, isNull);
    });

    test(
      'setMessage, setError, and clearFeedback keep only one feedback channel at a time',
      () {
        final notifier = PasswordResetOtpFlowNotifier();
        addTearDown(notifier.dispose);

        notifier.setMessage('Backend message');
        expect(notifier.state.message, 'Backend message');
        expect(notifier.state.errorMessage, isNull);

        notifier.setError('Backend error');
        expect(notifier.state.message, isNull);
        expect(notifier.state.errorMessage, 'Backend error');

        notifier.clearFeedback();
        expect(notifier.state.message, isNull);
        expect(notifier.state.errorMessage, isNull);
      },
    );
  });
}
