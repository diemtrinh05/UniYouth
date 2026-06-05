import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/domain/usecases/auth/forgot_password_usecase.dart';
import 'package:uniyouth_app/domain/usecases/auth/reset_password_usecase.dart';
import 'package:uniyouth_app/domain/usecases/auth/verify_reset_otp_usecase.dart';
import 'package:uniyouth_app/presentation/app/providers/app_provider_graph.dart';
import 'package:uniyouth_app/presentation/app/router/app_routes.dart';
import 'package:uniyouth_app/presentation/features/auth/enter_otp/enter_otp_page.dart';
import 'package:uniyouth_app/presentation/features/auth/forgot_password/forgot_password_page.dart';
import 'package:uniyouth_app/presentation/features/auth/reset_password/reset_password_page.dart';
import 'package:uniyouth_app/presentation/features/auth/state/password_reset_otp_flow_provider.dart';
import 'package:uniyouth_app/presentation/features/auth/state/password_reset_otp_flow_state.dart';

void main() {
  testWidgets(
    'navigates forgot password -> enter OTP -> reset password -> login',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final forgotRepository = _FakeForgotPasswordRepository();
      final verifyRepository = _FakeVerifyResetOtpRepository();
      final resetRepository = _FakeResetPasswordRepository();

      final forgotPasswordUseCase = ForgotPasswordUseCase(
        repository: forgotRepository,
      );
      final resetPasswordUseCase = ResetPasswordUseCase(
        repository: resetRepository,
      );

      final container = ProviderContainer(
        overrides: [
          forgotPasswordUseCaseProvider.overrideWithValue(
            forgotPasswordUseCase,
          ),
          verifyResetOtpUseCaseProvider.overrideWithValue(
            VerifyResetOtpUseCase(repository: verifyRepository),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: AppRoutes.forgotPassword,
            routes: <String, WidgetBuilder>{
              AppRoutes.forgotPassword: (_) => ForgotPasswordPage(
                forgotPasswordUseCase: forgotPasswordUseCase,
              ),
              AppRoutes.enterOtp: (_) => const EnterOtpPage(),
              AppRoutes.resetPassword: (_) =>
                  ResetPasswordPage(resetPasswordUseCase: resetPasswordUseCase),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ForgotPasswordPage), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).first,
        '  SV2001  ',
      );
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(forgotRepository.callCount, 1);
      expect(forgotRepository.lastAccount, 'SV2001');
      expect(find.byType(EnterOtpPage), findsOneWidget);
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).step,
        PasswordResetOtpFlowStep.enterOtp,
      );
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).email,
        'SV2001',
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(verifyRepository.callCount, 1);
      expect(verifyRepository.lastAccount, 'SV2001');
      expect(verifyRepository.lastOtpCode, '123456');
      expect(find.byType(ResetPasswordPage), findsOneWidget);
      expect(find.text('Xác thực OTP thành công.'), findsOneWidget);
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).step,
        PasswordResetOtpFlowStep.resetPassword,
      );
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).message,
        'Xác thực OTP thành công.',
      );
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).verificationTicket,
        'verification-ticket',
      );
      await tester.pump(const Duration(seconds: 1));

      final passwordFields = find.byType(TextFormField);
      expect(passwordFields, findsNWidgets(2));
      await tester.enterText(passwordFields.at(0), 'NewPass@123');
      await tester.enterText(passwordFields.at(1), 'NewPass@123');
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(resetRepository.callCount, 1);
      expect(resetRepository.lastVerificationTicket, 'verification-ticket');
      expect(resetRepository.lastNewPassword, 'NewPass@123');
      expect(find.text('LOGIN_SCREEN'), findsOneWidget);
      expect(find.byType(ForgotPasswordPage), findsNothing);
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).step,
        PasswordResetOtpFlowStep.enterEmail,
      );
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).email,
        isNull,
      );
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).verificationTicket,
        isNull,
      );
    },
  );

  testWidgets(
    'returns to enter OTP and clears verification ticket when reset ticket is expired',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final forgotRepository = _FakeForgotPasswordRepository();
      final verifyRepository = _FakeVerifyResetOtpRepository();
      final resetRepository = _FakeResetPasswordRepository(
        errorToThrow: const AppError(
          type: AppErrorType.badRequest,
          statusCode: 400,
          message: 'Verification ticket không hợp lệ hoặc đã hết hạn.',
          isBackendMessage: true,
        ),
      );

      final forgotPasswordUseCase = ForgotPasswordUseCase(
        repository: forgotRepository,
      );
      final resetPasswordUseCase = ResetPasswordUseCase(
        repository: resetRepository,
      );

      final container = ProviderContainer(
        overrides: [
          forgotPasswordUseCaseProvider.overrideWithValue(
            forgotPasswordUseCase,
          ),
          verifyResetOtpUseCaseProvider.overrideWithValue(
            VerifyResetOtpUseCase(repository: verifyRepository),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: AppRoutes.forgotPassword,
            routes: <String, WidgetBuilder>{
              AppRoutes.forgotPassword: (_) => ForgotPasswordPage(
                forgotPasswordUseCase: forgotPasswordUseCase,
              ),
              AppRoutes.enterOtp: (_) => const EnterOtpPage(),
              AppRoutes.resetPassword: (_) =>
                  ResetPasswordPage(resetPasswordUseCase: resetPasswordUseCase),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(
        find.byType(TextFormField).first,
        'SV2001',
      );
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ResetPasswordPage), findsOneWidget);

      final passwordFields = find.byType(TextFormField);
      expect(passwordFields, findsNWidgets(2));
      await tester.enterText(passwordFields.at(0), 'NewPass@123');
      await tester.enterText(passwordFields.at(1), 'NewPass@123');
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(resetRepository.callCount, 1);
      expect(resetRepository.lastVerificationTicket, 'verification-ticket');
      expect(find.byType(EnterOtpPage), findsOneWidget);
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).step,
        PasswordResetOtpFlowStep.enterOtp,
      );
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).verificationTicket,
        isNull,
      );
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).email,
        'SV2001',
      );
      expect(find.byType(ForgotPasswordPage), findsNothing);
    },
  );

  testWidgets(
    'preserves custom verify OTP success message through integration flow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const backendSuccessMessage = 'Backend verify success message 99';
      final forgotRepository = _FakeForgotPasswordRepository();
      final verifyRepository = _FakeVerifyResetOtpRepository(
        successMessage: backendSuccessMessage,
      );
      final resetRepository = _FakeResetPasswordRepository();

      final forgotPasswordUseCase = ForgotPasswordUseCase(
        repository: forgotRepository,
      );
      final resetPasswordUseCase = ResetPasswordUseCase(
        repository: resetRepository,
      );

      final container = ProviderContainer(
        overrides: [
          forgotPasswordUseCaseProvider.overrideWithValue(
            forgotPasswordUseCase,
          ),
          verifyResetOtpUseCaseProvider.overrideWithValue(
            VerifyResetOtpUseCase(repository: verifyRepository),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: AppRoutes.forgotPassword,
            routes: <String, WidgetBuilder>{
              AppRoutes.forgotPassword: (_) => ForgotPasswordPage(
                forgotPasswordUseCase: forgotPasswordUseCase,
              ),
              AppRoutes.enterOtp: (_) => const EnterOtpPage(),
              AppRoutes.resetPassword: (_) =>
                  ResetPasswordPage(resetPasswordUseCase: resetPasswordUseCase),
              AppRoutes.login: (_) =>
                  const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
            },
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(
        find.byType(TextFormField).first,
        'SV2001',
      );
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ResetPasswordPage), findsOneWidget);
      expect(find.text(backendSuccessMessage), findsOneWidget);
      expect(
        container.read(passwordResetOtpFlowNotifierProvider).message,
        backendSuccessMessage,
      );
      expect(find.text('Xác thực OTP thành công.'), findsNothing);
    },
  );
}

class _FakeForgotPasswordRepository implements ForgotPasswordRepository {
  int callCount = 0;
  String? lastAccount;

  @override
  Future<String> forgotPassword({required String account}) async {
    callCount += 1;
    lastAccount = account;
    return 'OTP sent';
  }
}

class _FakeVerifyResetOtpRepository implements VerifyResetOtpRepository {
  _FakeVerifyResetOtpRepository({
    this.successMessage = 'Xác thực OTP thành công.',
  });

  int callCount = 0;
  String? lastAccount;
  String? lastOtpCode;
  final String successMessage;

  @override
  Future<VerifyResetOtpResult> verifyResetOtp({
    required String account,
    required String otpCode,
  }) async {
    callCount += 1;
    lastAccount = account;
    lastOtpCode = otpCode;
    return VerifyResetOtpResult(
      message: successMessage,
      verificationTicket: 'verification-ticket',
      expiresAt: DateTime(2026, 3, 8, 10, 30, 0),
    );
  }
}

class _FakeResetPasswordRepository implements ResetPasswordRepository {
  _FakeResetPasswordRepository({this.errorToThrow});

  int callCount = 0;
  String? lastVerificationTicket;
  String? lastNewPassword;
  final Object? errorToThrow;

  @override
  Future<String> resetPassword({
    required String verificationTicket,
    required String newPassword,
  }) async {
    callCount += 1;
    lastVerificationTicket = verificationTicket;
    lastNewPassword = newPassword;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return 'Password reset success';
  }
}
