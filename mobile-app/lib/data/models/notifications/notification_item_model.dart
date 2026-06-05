class NotificationItemModel {
  const NotificationItemModel({
    required this.notificationId,
    required this.title,
    required this.content,
    required this.notificationType,
    required this.priority,
    required this.isRead,
    required this.readDate,
    required this.actionUrl,
    required this.eventId,
    required this.eventName,
    required this.createdDate,
    required this.expiryDate,
  });

  final int notificationId;
  final String? title;
  final String? content;
  final String? notificationType;
  final int? priority;
  final bool? isRead;
  final DateTime? readDate;
  final String? actionUrl;
  final int? eventId;
  final String? eventName;
  final DateTime? createdDate;
  final DateTime? expiryDate;

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      notificationId: _NotificationParser.parseInt(
        _readAny(json, const <String>['notificationID', 'notificationId']),
      ),
      title: json['title']?.toString(),
      content: json['content']?.toString(),
      notificationType: json['notificationType']?.toString(),
      priority: _NotificationParser.parseNullableInt(json['priority']),
      isRead: _NotificationParser.parseNullableBool(json['isRead']),
      readDate: _NotificationParser.parseNullableDateTime(json['readDate']),
      actionUrl: json['actionUrl']?.toString(),
      eventId: _NotificationParser.parseNullableInt(
        _readAny(json, const <String>['eventID', 'eventId']),
      ),
      eventName: json['eventName']?.toString(),
      createdDate: _NotificationParser.parseNullableDateTime(
        json['createdDate'],
      ),
      expiryDate: _NotificationParser.parseNullableDateTime(json['expiryDate']),
    );
  }

  static Object? _readAny(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }
    return null;
  }
}

class NotificationListPageModel {
  const NotificationListPageModel({
    required this.notifications,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.unreadCount,
  });

  final List<NotificationItemModel> notifications;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final int unreadCount;

  factory NotificationListPageModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final mappedData = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return NotificationListPageModel.fromJson(mappedData);
    }
    return NotificationListPageModel.fromJson(json);
  }

  factory NotificationListPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['notifications'];
    final parsedItems = <NotificationItemModel>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          final mappedItem = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          parsedItems.add(NotificationItemModel.fromJson(mappedItem));
        }
      }
    }

    return NotificationListPageModel(
      notifications: List<NotificationItemModel>.unmodifiable(parsedItems),
      totalCount: _NotificationParser.parseInt(json['totalCount']),
      pageNumber: _NotificationParser.parseInt(
        json['pageNumber'],
        defaultValue: 1,
      ),
      pageSize: _NotificationParser.parseInt(
        json['pageSize'],
        defaultValue: 20,
      ),
      totalPages: _NotificationParser.parseInt(
        json['totalPages'],
        defaultValue: 1,
      ),
      hasPreviousPage: _NotificationParser.parseBool(json['hasPreviousPage']),
      hasNextPage: _NotificationParser.parseBool(json['hasNextPage']),
      unreadCount: _NotificationParser.parseInt(json['unreadCount']),
    );
  }
}

class _NotificationParser {
  static int parseInt(Object? raw, {int defaultValue = 0}) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw) ?? defaultValue;
    }
    return defaultValue;
  }

  static int? parseNullableInt(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  static bool parseBool(Object? raw, {bool defaultValue = false}) {
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return defaultValue;
  }

  static bool? parseNullableBool(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return null;
  }

  static DateTime? parseNullableDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    final parsed = DateTime.tryParse(raw.toString());
    return parsed;
  }
}
