class EventListItemModel {
  const EventListItemModel({
    required this.eventId,
    required this.eventName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    required this.statusName,
    required this.eventTypeName,
    required this.instituteName,
    required this.registrationDeadline,
    required this.thumbnailUrl,
    required this.hasAvailableSlots,
  });

  final int eventId;
  final String eventName;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? locationName;
  final int? maxParticipants;
  final int? currentParticipants;
  final int status;
  final String? statusName;
  final String? eventTypeName;
  final String? instituteName;
  final DateTime? registrationDeadline;
  final String? thumbnailUrl;
  final bool hasAvailableSlots;

  factory EventListItemModel.fromJson(Map<String, dynamic> json) {
    return EventListItemModel(
      eventId: _parseInt(json['eventId']),
      eventName: (json['eventName']?.toString() ?? '').trim(),
      description: json['description']?.toString(),
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      locationName: json['locationName']?.toString(),
      maxParticipants: _parseNullableInt(json['maxParticipants']),
      currentParticipants: _parseNullableInt(json['currentParticipants']),
      status: _parseInt(json['status']),
      statusName: json['statusName']?.toString(),
      eventTypeName: json['eventTypeName']?.toString(),
      instituteName: json['instituteName']?.toString(),
      registrationDeadline: _parseNullableDateTime(
        json['registrationDeadline'],
      ),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      hasAvailableSlots: _parseBool(json['hasAvailableSlots']),
    );
  }

  static int _parseInt(Object? raw, {int defaultValue = 0}) {
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw) ?? defaultValue;
    }
    return defaultValue;
  }

  static int? _parseNullableInt(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  static bool _parseBool(Object? raw, {bool defaultValue = false}) {
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      final value = raw.trim().toLowerCase();
      if (value == 'true') {
        return true;
      }
      if (value == 'false') {
        return false;
      }
    }
    return defaultValue;
  }

  static DateTime _parseDateTime(Object? raw) {
    final value = DateTime.tryParse(raw?.toString() ?? '');
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return value;
  }

  static DateTime? _parseNullableDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    final value = DateTime.tryParse(raw.toString());
    return value;
  }
}

class EventListPageModel {
  const EventListPageModel({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<EventListItemModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  factory EventListPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsedItems = <EventListItemModel>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          final mapped = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          parsedItems.add(EventListItemModel.fromJson(mapped));
        }
      }
    }

    return EventListPageModel(
      items: List<EventListItemModel>.unmodifiable(parsedItems),
      totalCount: EventListItemModel._parseInt(json['totalCount']),
      pageNumber: EventListItemModel._parseInt(
        json['pageNumber'],
        defaultValue: 1,
      ),
      pageSize: EventListItemModel._parseInt(
        json['pageSize'],
        defaultValue: 10,
      ),
      totalPages: EventListItemModel._parseInt(
        json['totalPages'],
        defaultValue: 1,
      ),
      hasPreviousPage: EventListItemModel._parseBool(json['hasPreviousPage']),
      hasNextPage: EventListItemModel._parseBool(json['hasNextPage']),
    );
  }
}
