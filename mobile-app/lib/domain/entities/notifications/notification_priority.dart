enum NotificationPriority {
  normal,
  high,
  critical,
  unknown,
}

extension NotificationPriorityParser on NotificationPriority {
  static NotificationPriority fromApiValue(Object? rawValue) {
    if (rawValue == null) {
      return NotificationPriority.unknown;
    }

    if (rawValue is int) {
      switch (rawValue) {
        case 0:
          return NotificationPriority.normal;
        case 1:
          return NotificationPriority.high;
        case 2:
          return NotificationPriority.critical;
        default:
          return NotificationPriority.unknown;
      }
    }

    final normalized = rawValue.toString().trim().toLowerCase();
    if (normalized.isEmpty) {
      return NotificationPriority.unknown;
    }

    switch (normalized) {
      case '0':
      case 'normal':
        return NotificationPriority.normal;
      case '1':
      case 'high':
        return NotificationPriority.high;
      case '2':
      case 'critical':
        return NotificationPriority.critical;
      default:
        return NotificationPriority.unknown;
    }
  }
}

