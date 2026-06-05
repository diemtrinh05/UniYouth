import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_service.dart';
import 'notification_observability_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await ensureFirebaseCoreInitialized();
  } catch (_) {
    // Background isolate must stay resilient even if Firebase is already ready.
  }

  const logger = NotificationObservabilityLogger();
  logger.logPushReceipt(
    source: 'background_isolate',
    messageId: message.messageId,
    payload: Map<String, dynamic>.from(message.data),
    hasVisualContent: message.notification != null,
  );
}
