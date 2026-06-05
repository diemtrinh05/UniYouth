import 'device_push_platform.dart';

class DevicePushPlatformResolver {
  DevicePushPlatform resolve() {
    // Current mobile integration uses Firebase Messaging token across platforms.
    // Per activation plan, register Firebase token as FCM platform (1).
    return DevicePushPlatform.fcm;
  }
}
