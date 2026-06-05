import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_service.dart';

abstract class DevicePushTokenProvider {
  Future<String?> getToken();
}

class FirebaseDevicePushTokenProvider implements DevicePushTokenProvider {
  @override
  Future<String?> getToken() async {
    try {
      await ensureFirebaseCoreInitialized();
      final token = await FirebaseMessaging.instance.getToken();
      final normalized = token?.trim();
      if (normalized == null || normalized.isEmpty) {
        return null;
      }
      return normalized;
    } catch (_) {
      return null;
    }
  }
}
