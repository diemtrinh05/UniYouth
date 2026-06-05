enum DevicePushPlatform {
  fcm,
  apns,
}

extension DevicePushPlatformApiValue on DevicePushPlatform {
  int get apiValue {
    switch (this) {
      case DevicePushPlatform.fcm:
        return 1;
      case DevicePushPlatform.apns:
        return 2;
    }
  }
}
