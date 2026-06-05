import 'package:flutter/material.dart';

import '../../../domain/entities/events/event_status.dart';

class EventStatusUiMapper {
  const EventStatusUiMapper._();

  static Color foregroundColor(int status) {
    switch (EventStatusParser.fromApiValue(status)) {
      case EventStatus.open:
      case EventStatus.ongoing:
        return const Color(0xFF2E7D32);
      case EventStatus.closed:
      case EventStatus.cancelled:
        return const Color(0xFFC62828);
      case EventStatus.draft:
      case EventStatus.unknown:
        return const Color(0xFFE65100);
    }
  }

  static Color backgroundColor(int status, {double alpha = 0.1}) {
    return foregroundColor(status).withValues(alpha: alpha);
  }
}

