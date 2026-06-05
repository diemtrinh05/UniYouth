import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/presentation/app/router/app_route_stack_observer.dart';

void main() {
  test('tracks app shell route presence across push, pop and replace', () {
    final observer = AppRouteStackObserver();
    final appRoute = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/app'),
      builder: (_) => const SizedBox.shrink(),
    );
    final notificationsRoute = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/notifications'),
      builder: (_) => const SizedBox.shrink(),
    );
    final eventDetailRoute = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/events/detail'),
      builder: (_) => const SizedBox.shrink(),
    );

    observer.didPush(appRoute, null);
    expect(observer.containsRoute('/app'), isTrue);
    expect(observer.currentRouteName, '/app');

    observer.didPush(notificationsRoute, appRoute);
    expect(observer.containsRoute('/app'), isTrue);
    expect(observer.currentRouteName, '/notifications');

    observer.didPop(notificationsRoute, appRoute);
    expect(observer.containsRoute('/app'), isTrue);
    expect(observer.currentRouteName, '/app');

    observer.didReplace(newRoute: eventDetailRoute, oldRoute: appRoute);
    expect(observer.containsRoute('/app'), isFalse);
    expect(observer.currentRouteName, '/events/detail');
  });
}
