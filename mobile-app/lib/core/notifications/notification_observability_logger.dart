import 'dart:developer' as developer;

import 'notification_payload_log_sanitizer.dart';

class NotificationObservabilityLogger {
  const NotificationObservabilityLogger({
    this.enableDebugLogs = true,
  });

  static const bool _isProduct = bool.fromEnvironment('dart.vm.product');

  final bool enableDebugLogs;

  void logTokenLifecycle({
    required String action,
    required String status,
    String? platform,
    bool? hasToken,
    Object? error,
  }) {
    if (!_canLog) {
      return;
    }

    final errorType = error == null ? '-' : error.runtimeType.toString();
    developer.log(
      'token_lifecycle action=$action status=$status '
      'platform=${platform ?? "-"} hasToken=${hasToken ?? false} '
      'errorType=$errorType',
      name: 'notifications',
    );
  }

  void logPushReceipt({
    required String source,
    String? messageId,
    Map<String, dynamic>? payload,
    bool? hasVisualContent,
  }) {
    if (!_canLog) {
      return;
    }

    final payloadSummary = NotificationPayloadLogSanitizer.summarize(payload);
    developer.log(
      'push_receipt source=$source messageId=${messageId ?? "-"} '
      'hasVisualContent=${hasVisualContent ?? false} '
      '$payloadSummary',
      name: 'notifications',
    );
  }

  void logNavigationDecision({
    required String routeName,
    required bool hasArguments,
    required String reason,
    String? actionUrl,
    Map<String, dynamic>? payload,
  }) {
    if (!_canLog) {
      return;
    }

    final payloadSummary = NotificationPayloadLogSanitizer.summarize(payload);
    final actionUrlSummary = NotificationPayloadLogSanitizer.sanitizeActionUrl(
      actionUrl,
    );
    developer.log(
      'notification_navigation route=$routeName hasArgs=$hasArguments '
      'reason=$reason actionUrl=$actionUrlSummary '
      '$payloadSummary',
      name: 'notifications',
    );
  }

  bool get _canLog => !_isProduct && enableDebugLogs;
}
