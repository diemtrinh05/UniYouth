import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/auth/unauthorized_session_handler.dart';

void main() {
  test('clears local session before redirecting to login', () async {
    final callOrder = <String>[];
    final handler = UnauthorizedSessionHandler(
      clearLocalSession: () async {
        callOrder.add('clear');
      },
      redirectToLogin: () async {
        callOrder.add('redirect');
      },
    );

    await handler.handleUnauthorized();

    expect(callOrder, <String>['clear', 'redirect']);
  });

  test('dedupes unauthorized bursts inside the dedupe window', () async {
    var clearCallCount = 0;
    var redirectCallCount = 0;
    final handler = UnauthorizedSessionHandler(
      clearLocalSession: () async {
        clearCallCount += 1;
      },
      redirectToLogin: () async {
        redirectCallCount += 1;
      },
    );

    await handler.handleUnauthorized();
    await handler.handleUnauthorized();

    expect(clearCallCount, 1);
    expect(redirectCallCount, 1);
  });
}
