import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniyouth_app/domain/usecases/auth/bootstrap_auth_usecase.dart';
import 'package:uniyouth_app/domain/usecases/auth/check_api_health_usecase.dart';
import 'package:uniyouth_app/domain/usecases/auth/login_usecase.dart';
import 'package:uniyouth_app/presentation/app/providers/app_provider_graph.dart';
import 'package:uniyouth_app/presentation/app/router/app_routes.dart';
import 'package:uniyouth_app/presentation/features/auth/login/login_page.restored.dart';
import 'package:uniyouth_app/presentation/features/splash/splash_page.dart';

import '../../test_support/provider_overrides.dart';

void main() {
  testWidgets('navigates from splash to login then to app shell after login', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final loginRepository = _FakeLoginRepository();
    final loginUseCase = LoginUseCase(repository: loginRepository);
    final bootstrapUseCase = BootstrapAuthUseCase(
      repository: _FakeBootstrapAuthRepository(),
    );
    final healthUseCase = CheckApiHealthUseCase(
      repository: _FakeHealthRepository(),
    );
    final apiConfigService = await createTestApiConfigService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigServiceProvider.overrideWithValue(apiConfigService),
        ],
        child: MaterialApp(
          initialRoute: AppRoutes.splash,
          routes: <String, WidgetBuilder>{
            AppRoutes.splash: (_) => SplashPage(
              loginUseCase: loginUseCase,
              bootstrapAuthUseCase: bootstrapUseCase,
              checkApiHealthUseCase: healthUseCase,
              onAuthenticatedTokenSync: () async => false,
              consumeNotificationPermissionDeniedHint: () => false,
            ),
            AppRoutes.login: (_) => LoginPage(
              loginUseCase: loginUseCase,
              onAuthenticatedTokenSync: () async => false,
              consumeNotificationPermissionDeniedHint: () => false,
            ),
            AppRoutes.app: (_) =>
                const Scaffold(body: Center(child: Text('APP_SHELL'))),
            AppRoutes.forgotPassword: (_) => const SizedBox.shrink(),
          },
        ),
      ),
    );

    await tester.pump();
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(LoginPage).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byType(LoginPage), findsOneWidget);

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), 'sv001');
    await tester.enterText(textFields.at(1), 'secret');
    await tester.ensureVisible(find.byType(ElevatedButton).first);
    await tester.pump();
    final loginButton = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton).first,
    );
    loginButton.onPressed?.call();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('APP_SHELL').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(loginRepository.callCount, 1);
    expect(loginRepository.lastStudentCode, 'sv001');
    expect(find.text('APP_SHELL'), findsOneWidget);
  });

  testWidgets(
    'continues pending post-login navigation before app shell fallback',
    (tester) async {
      final loginRepository = _FakeLoginRepository();
      final loginUseCase = LoginUseCase(repository: loginRepository);
      final apiConfigService = await createTestApiConfigService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiConfigServiceProvider.overrideWithValue(apiConfigService),
          ],
          child: MaterialApp(
            routes: <String, WidgetBuilder>{
              AppRoutes.login: (_) => LoginPage(
                loginUseCase: loginUseCase,
                onAuthenticatedTokenSync: () async => false,
                consumeNotificationPermissionDeniedHint: () => false,
                onPendingPostLoginNavigation: (navigator) async {
                  await navigator.pushNamedAndRemoveUntil(
                    AppRoutes.notifications,
                    (_) => false,
                  );
                  return true;
                },
              ),
              AppRoutes.app: (_) =>
                  const Scaffold(body: Center(child: Text('APP_SHELL'))),
              AppRoutes.notifications: (_) =>
                  const Scaffold(body: Center(child: Text('NOTIFICATIONS'))),
              AppRoutes.forgotPassword: (_) => const SizedBox.shrink(),
            },
            initialRoute: AppRoutes.login,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'sv002');
      await tester.enterText(textFields.at(1), 'secret');
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      final loginButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      loginButton.onPressed?.call();
      await tester.pumpAndSettle();

      expect(loginRepository.callCount, 1);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('APP_SHELL'), findsNothing);
    },
  );

  testWidgets(
    'continues pending event detail navigation before app shell fallback',
    (tester) async {
      final loginRepository = _FakeLoginRepository();
      final loginUseCase = LoginUseCase(repository: loginRepository);
      final apiConfigService = await createTestApiConfigService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiConfigServiceProvider.overrideWithValue(apiConfigService),
          ],
          child: MaterialApp(
            routes: <String, WidgetBuilder>{
              AppRoutes.login: (_) => LoginPage(
                loginUseCase: loginUseCase,
                onAuthenticatedTokenSync: () async => false,
                consumeNotificationPermissionDeniedHint: () => false,
                onPendingPostLoginNavigation: (navigator) async {
                  await navigator.pushNamedAndRemoveUntil(
                    AppRoutes.eventDetail,
                    (_) => false,
                    arguments: 42,
                  );
                  return true;
                },
              ),
              AppRoutes.app: (_) =>
                  const Scaffold(body: Center(child: Text('APP_SHELL'))),
              AppRoutes.eventDetail: (context) {
                final eventId =
                    ModalRoute.of(context)?.settings.arguments as int?;
                return Scaffold(
                  body: Center(child: Text('EVENT_DETAIL_$eventId')),
                );
              },
              AppRoutes.forgotPassword: (_) => const SizedBox.shrink(),
            },
            initialRoute: AppRoutes.login,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      await tester.enterText(textFields.at(0), 'sv003');
      await tester.enterText(textFields.at(1), 'secret');
      await tester.ensureVisible(find.byType(ElevatedButton).first);
      await tester.pump();
      final loginButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      loginButton.onPressed?.call();
      await tester.pumpAndSettle();

      expect(loginRepository.callCount, 1);
      expect(find.text('EVENT_DETAIL_42'), findsOneWidget);
      expect(find.text('APP_SHELL'), findsNothing);
    },
  );
}

class _FakeLoginRepository implements LoginRepository {
  int callCount = 0;
  String? lastStudentCode;
  String? lastPassword;

  @override
  Future<void> login({
    required String code,
    required String password,
  }) async {
    callCount += 1;
    lastStudentCode = code;
    lastPassword = password;
  }
}

class _FakeBootstrapAuthRepository implements BootstrapAuthRepository {
  @override
  Future<AuthBootstrapResult> bootstrap() async {
    return AuthBootstrapResult.unauthenticated;
  }
}

class _FakeHealthRepository implements CheckApiHealthRepository {
  @override
  Future<bool> checkApiHealth() async {
    return true;
  }
}

