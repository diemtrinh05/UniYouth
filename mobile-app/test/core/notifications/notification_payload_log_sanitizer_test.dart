import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/notifications/notification_payload_log_sanitizer.dart';

void main() {
  group('NotificationPayloadLogSanitizer.summarize', () {
    test('returns null marker for null payload', () {
      expect(NotificationPayloadLogSanitizer.summarize(null), 'payload=null');
    });

    test('returns empty marker for empty payload', () {
      expect(
        NotificationPayloadLogSanitizer.summarize(<String, dynamic>{}),
        'payload=empty',
      );
    });

    test('redacts sensitive keys', () {
      final summary = NotificationPayloadLogSanitizer.summarize(
        <String, dynamic>{
          'token': 'very-secret-token',
          'title': 'hello',
        },
      );

      expect(summary, contains('token=<redacted>'));
      expect(summary, contains('title'));
      expect(summary, isNot(contains('very-secret-token')));
    });

    test('limits logged keys and appends ellipsis when payload is large', () {
      final payload = <String, dynamic>{
        'k1': 1,
        'k2': 2,
        'k3': 3,
        'k4': 4,
        'k5': 5,
        'k6': 6,
        'k7': 7,
        'k8': 8,
        'k9': 9,
      };

      final summary = NotificationPayloadLogSanitizer.summarize(payload);
      expect(summary, contains('payloadKeys=9'));
      expect(summary, contains('...'));
    });
  });

  group('NotificationPayloadLogSanitizer.sanitizeActionUrl', () {
    test('returns dash for null or blank actionUrl', () {
      expect(NotificationPayloadLogSanitizer.sanitizeActionUrl(null), '-');
      expect(NotificationPayloadLogSanitizer.sanitizeActionUrl('  '), '-');
    });

    test('removes query from absolute url', () {
      final sanitized = NotificationPayloadLogSanitizer.sanitizeActionUrl(
        'https://api.example.com/events/detail?token=abc&x=1',
      );

      expect(sanitized, 'https://api.example.com/events/detail');
      expect(sanitized, isNot(contains('token=')));
    });

    test('normalizes relative path', () {
      final sanitized = NotificationPayloadLogSanitizer.sanitizeActionUrl(
        'notifications/',
      );

      expect(sanitized, '/notifications');
    });
  });
}
