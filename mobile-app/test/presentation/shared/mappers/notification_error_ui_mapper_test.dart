import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/presentation/shared/mappers/notification_error_ui_mapper.dart';

void main() {
  group('NotificationErrorUiMapper.permission prompt labels', () {
    test('returns non-empty guidance and labels', () {
      expect(
        NotificationErrorUiMapper.permissionDeniedGuidanceMessage().trim(),
        isNotEmpty,
      );
      expect(NotificationErrorUiMapper.openSettingsLabel().trim(), isNotEmpty);
      expect(NotificationErrorUiMapper.remindLaterLabel().trim(), isNotEmpty);
    });
  });

  group('NotificationErrorUiMapper.message', () {
    test('keeps backend message when statusCode exists', () {
      const backendMessage = 'backend_message_123';
      final error = AppError(
        type: AppErrorType.badRequest,
        statusCode: 400,
        message: backendMessage,
      );

      final message = NotificationErrorUiMapper.message(
        error,
        operation: NotificationErrorOperation.loadNotifications,
      );

      expect(message, contains(backendMessage));
    });

    test('uses network fallback for network errors without backend message', () {
      final error = AppError(
        type: AppErrorType.network,
        statusCode: null,
        message: 'Network error.',
      );

      final message = NotificationErrorUiMapper.message(
        error,
        operation: NotificationErrorOperation.refreshNotifications,
      );

      expect(message.trim(), isNotEmpty);
      expect(message, isNot(contains('Network error.')));
    });
  });
}
