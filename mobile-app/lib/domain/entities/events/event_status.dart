enum EventStatus {
  draft,
  open,
  ongoing,
  closed,
  cancelled,
  unknown,
}

extension EventStatusParser on EventStatus {
  static EventStatus fromApiValue(int value) {
    switch (value) {
      case 0:
        return EventStatus.draft;
      case 1:
        return EventStatus.open;
      case 2:
        return EventStatus.ongoing;
      case 3:
        return EventStatus.closed;
      case 4:
        return EventStatus.cancelled;
      default:
        return EventStatus.unknown;
    }
  }
}

