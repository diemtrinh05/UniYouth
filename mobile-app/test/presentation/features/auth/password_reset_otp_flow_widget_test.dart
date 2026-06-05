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
  group('password reset OTP route guard', () {
    testWidgets(
      'navigates forgot password back action to login screen',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            forgotPasswordUseCaseProvider.overrideWithValue(
              ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
            ),
            verifyResetOtpUseCaseProvider.overrideWithValue(
              VerifyResetOtpUseCase(
                repository: _FakeVerifyResetOtpRepository(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _TestPasswordResetApp(
              forgotPasswordUseCase: ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
              resetPasswordUseCase: ResetPasswordUseCase(
                repository: _FakeResetPasswordRepository(),
              ),
              initialRoute: AppRoutes.forgotPassword,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ForgotPasswordPage), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('LOGIN_SCREEN'), findsOneWidget);
        expect(find.byType(ForgotPasswordPage), findsNothing);
      },
    );

    testWidgets(
      'redirects reset password route to forgot password when ticket is missing',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            forgotPasswordUseCaseProvider.overrideWithValue(
              ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
            ),
            verifyResetOtpUseCaseProvider.overrideWithValue(
              VerifyResetOtpUseCase(
                repository: _FakeVerifyResetOtpRepository(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _TestPasswordResetApp(
              forgotPasswordUseCase: ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
              resetPasswordUseCase: ResetPasswordUseCase(
                repository: _FakeResetPasswordRepository(),
              ),
              initialRoute: AppRoutes.resetPassword,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ForgotPasswordPage), findsOneWidget);
        expect(
          container
              .read(passwordResetOtpFlowNotifierProvider)
              .hasVerificationTicket,
          isFalse,
        );
      },
    );

    testWidgets(
      'redirects enter OTP route to forgot password when email is missing',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            forgotPasswordUseCaseProvider.overrideWithValue(
              ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
            ),
            verifyResetOtpUseCaseProvider.overrideWithValue(
              VerifyResetOtpUseCase(
                repository: _FakeVerifyResetOtpRepository(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _TestPasswordResetApp(
              forgotPasswordUseCase: ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
              resetPasswordUseCase: ResetPasswordUseCase(
                repository: _FakeResetPasswordRepository(),
              ),
              initialRoute: AppRoutes.enterOtp,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ForgotPasswordPage), findsOneWidget);
        expect(
          container.read(passwordResetOtpFlowNotifierProvider).hasEmail,
          isFalse,
        );
      },
    );

    testWidgets(
      'clears verification ticket and returns to enter OTP when reset ticket is invalid',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final resetRepository = _FakeResetPasswordRepository(
          errorToThrow: const AppError(
            type: AppErrorType.badRequest,
            statusCode: 400,
            message: 'Verification ticket không hợp lệ hoặc đã hết hạn.',
            isBackendMessage: true,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            forgotPasswordUseCaseProvider.overrideWithValue(
              ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
            ),
            verifyResetOtpUseCaseProvider.overrideWithValue(
              VerifyResetOtpUseCase(
                repository: _FakeVerifyResetOtpRepository(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(passwordResetOtpFlowNotifierProvider.notifier)
            .beginOtpStep(
              email: 'SV2001',
              otpExpiresAt: DateTime(2026, 3, 9, 10, 5, 0),
              resendAvailableAt: DateTime(2026, 3, 9, 10, 0, 30),
            );
        container
            .read(passwordResetOtpFlowNotifierProvider.notifier)
            .setVerificationResult(
              verificationTicket: 'expired-ticket',
              verificationTicketExpiresAt: DateTime(2026, 3, 9, 10, 10, 0),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _TestPasswordResetApp(
              forgotPasswordUseCase: ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
              resetPasswordUseCase: ResetPasswordUseCase(
                repository: resetRepository,
              ),
              initialRoute: AppRoutes.enterOtp,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        Navigator.of(
          tester.element(find.byType(EnterOtpPage)),
        ).pushNamed(AppRoutes.resetPassword);
        await tester.pumpAndSettle();

        final passwordFields = find.byType(TextFormField);
        expect(passwordFields, findsNWidgets(2));
        await tester.enterText(passwordFields.at(0), 'NewPass@123');
        await tester.enterText(passwordFields.at(1), 'NewPass@123');
        await tester.ensureVisible(find.byType(ElevatedButton).first);
        await tester.pump();
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(EnterOtpPage), findsOneWidget);
        expect(find.byType(ForgotPasswordPage), findsNothing);
        expect(
          container.read(passwordResetOtpFlowNotifierProvider).step,
          PasswordResetOtpFlowStep.enterOtp,
        );
        expect(
          container.read(passwordResetOtpFlowNotifierProvider).verificationTicket,
          isNull,
        );
        expect(
          container.read(passwordResetOtpFlowNotifierProvider).message,
          contains('Verification ticket'),
        );
      },
    );

    testWidgets(
      'shows stronger local expired OTP feedback when countdown reaches zero',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final container = ProviderContainer(
          overrides: [
            forgotPasswordUseCaseProvider.overrideWithValue(
              ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
            ),
            verifyResetOtpUseCaseProvider.overrideWithValue(
              VerifyResetOtpUseCase(
                repository: _FakeVerifyResetOtpRepository(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(passwordResetOtpFlowNotifierProvider.notifier)
            .beginOtpStep(
              email: 'SV2001',
              otpExpiresAt: DateTime.now().subtract(const Duration(seconds: 5)),
              resendAvailableAt: DateTime.now().subtract(
                const Duration(seconds: 1),
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _TestPasswordResetApp(
              forgotPasswordUseCase: ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
              resetPasswordUseCase: ResetPasswordUseCase(
                repository: _FakeResetPasswordRepository(),
              ),
              initialRoute: AppRoutes.enterOtp,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.text('Gửi lại mã OTP mới'), findsOneWidget);
        expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull,
        );
      },
    );

    testWidgets(
      'preserves custom verify OTP success message from backend on reset screen',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const backendSuccessMessage = 'Backend verify success message 42';
        final container = ProviderContainer(
          overrides: [
            forgotPasswordUseCaseProvider.overrideWithValue(
              ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
            ),
            verifyResetOtpUseCaseProvider.overrideWithValue(
              VerifyResetOtpUseCase(
                repository: _FakeVerifyResetOtpRepository(
                  successMessage: backendSuccessMessage,
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(passwordResetOtpFlowNotifierProvider.notifier)
            .beginOtpStep(
              email: 'SV2001',
              otpExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
              resendAvailableAt: DateTime.now().add(
                const Duration(seconds: 30),
              ),
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _TestPasswordResetApp(
              forgotPasswordUseCase: ForgotPasswordUseCase(
                repository: _FakeForgotPasswordRepository(),
              ),
              resetPasswordUseCase: ResetPasswordUseCase(
                repository: _FakeResetPasswordRepository(),
              ),
              initialRoute: AppRoutes.enterOtp,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextFormField).first, '123456');
        await tester.ensureVisible(find.byType(ElevatedButton).first);
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ResetPasswordPage), findsOneWidget);
        expect(find.text(backendSuccessMessage), findsOneWidget);
        expect(
          container.read(passwordResetOtpFlowNotifierProvider).message,
          backendSuccessMessage,
        );
        expect(find.text('Xác thực OTP thành công.'), findsNothing);
      },
    );
  });
}

class _TestPasswordResetApp extends StatelessWidget {
  const _TestPasswordResetApp({
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.initialRoute,
  });

  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: <String, WidgetBuilder>{
        AppRoutes.forgotPassword: (_) =>
            ForgotPasswordPage(forgotPasswordUseCase: forgotPasswordUseCase),
        AppRoutes.enterOtp: (_) => const EnterOtpPage(),
        AppRoutes.resetPassword: (_) =>
            ResetPasswordPage(resetPasswordUseCase: resetPasswordUseCase),
        AppRoutes.login: (_) =>
            const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
      },
    );
  }
}

class _FakeForgotPasswordRepository implements ForgotPasswordRepository {
  @override
  Future<String> forgotPassword({required String account}) async {
    return 'OTP sent';
  }
}

class _FakeVerifyResetOtpRepository implements VerifyResetOtpRepository {
  _FakeVerifyResetOtpRepository({
    this.successMessage = 'Xác thực OTP thành công.',
  });

  final String successMessage;

  @override
  Future<VerifyResetOtpResult> verifyResetOtp({
    required String account,
    required String otpCode,
  }) async {
    return VerifyResetOtpResult(
      message: successMessage,
      verificationTicket: 'ticket',
      expiresAt: DateTime(2026, 3, 8, 10, 30, 0),
    );
  }
}

class _FakeResetPasswordRepository implements ResetPasswordRepository {
  _FakeResetPasswordRepository({this.errorToThrow});

  final Object? errorToThrow;

  @override
  Future<String> resetPassword({
    required String verificationTicket,
    required String newPassword,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return 'Password reset success';
  }
}
