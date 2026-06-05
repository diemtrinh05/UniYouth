import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/presentation/app/router/app_routes.dart';

void main() {
  testWidgets('logout resets route stack to login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.app,
        routes: <String, WidgetBuilder>{
          AppRoutes.app: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                },
                child: const Text('LOGOUT'),
              ),
            ),
          ),
          AppRoutes.login: (_) =>
              const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
        },
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('LOGOUT'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    expect(find.text('LOGOUT'), findsNothing);
  });
}
