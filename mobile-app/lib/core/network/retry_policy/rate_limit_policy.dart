enum SensitiveApiAction { login, eventRegister, attendanceCheckIn }

class RateLimitPolicy {
  const RateLimitPolicy._();

  static Duration cooldownFor(SensitiveApiAction action) {
    switch (action) {
      case SensitiveApiAction.login:
        return const Duration(seconds: 30);
      case SensitiveApiAction.eventRegister:
        return const Duration(seconds: 20);
      case SensitiveApiAction.attendanceCheckIn:
        return const Duration(seconds: 20);
    }
  }

  static String retryLabel({required int seconds}) {
    return 'Thử lại sau $seconds giây';
  }

  static String cooldownMessage({required int seconds, String? backendMessage}) {
    final normalizedBackendMessage = (backendMessage ?? '').trim();
    final base =
        normalizedBackendMessage.isNotEmpty ? normalizedBackendMessage : 'Bạn thao tác quá nhanh.';
    return '$base Vui lòng chờ $seconds giây rồi thử lại.';
  }
}
