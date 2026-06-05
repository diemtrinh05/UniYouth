import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/notifications/notification_navigation_handler.dart';

void main() {
  group('NotificationNavigationHandler.resolveTarget', () {
    const handler = NotificationNavigationHandler(
      notificationsRoute: '/notifications',
      eventDetailRoute: '/events/detail',
      enableDebugLogs: false,
    );

    test('routes to event detail when eventId is present', () {
      final target = handler.resolveTarget(<String, dynamic>{'eventId': '12'});

      expect(target.routeName, '/events/detail');
      expect(target.arguments, 12);
    });

    test('routes to event detail when actionUrl contains event path', () {
      final target = handler.resolveTarget(<String, dynamic>{
        'actionUrl': 'https://example.com/events/42',
      });

      expect(target.routeName, '/events/detail');
      expect(target.arguments, 42);
    });

    test('routes to notifications when actionUrl points to notifications path', () {
      final target = handler.resolveTarget(<String, dynamic>{
        'actionUrl': '/notifications',
      });

      expect(target.routeName, '/notifications');
      expect(target.arguments, isNull);
    });

    test('falls back to notifications when payload is invalid', () {
      final target = handler.resolveTarget(<String, dynamic>{
        'eventId': '0',
        'actionUrl': '/events/not-a-number',
      });

      expect(target.routeName, '/notifications');
      expect(target.arguments, isNull);
    });

    test('falls back to notifications when payload is null', () {
      final target = handler.resolveTarget(null);

      expect(target.routeName, '/notifications');
      expect(target.arguments, isNull);
    });
  });
}
