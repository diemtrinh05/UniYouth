enum NotificationType {
  eventRegistration,
  attendance,
  eventUpdate,
  eventCancellation,
  eventReminder,
  manualPoints,
  system,
  unknown,
}

extension NotificationTypeParser on NotificationType {
  static NotificationType fromApiValue(String? rawValue) {
    final normalized = (rawValue ?? '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return NotificationType.unknown;
    }

    final compact = normalized.replaceAll(RegExp(r'[\s_-]'), '');
    switch (compact) {
      case 'eventregistration':
        return NotificationType.eventRegistration;
      case 'attendance':
        return NotificationType.attendance;
      case 'eventupdate':
        return NotificationType.eventUpdate;
      case 'eventcancellation':
        return NotificationType.eventCancellation;
      case 'eventreminder':
        return NotificationType.eventReminder;
      case 'manualpoints':
        return NotificationType.manualPoints;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.unknown;
    }
  }
}

