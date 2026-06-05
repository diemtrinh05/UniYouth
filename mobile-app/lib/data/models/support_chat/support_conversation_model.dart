class SupportConversationModel {
  const SupportConversationModel({
    required this.conversationId,
    required this.studentUserId,
    required this.studentCode,
    required this.studentFullName,
    required this.assignedToUserId,
    required this.assignedToFullName,
    required this.subject,
    required this.status,
    required this.statusName,
    required this.priority,
    required this.priorityName,
    required this.lastMessagePreview,
    required this.unreadCount,
    required this.lastMessageAt,
    required this.closedAt,
    required this.createdDate,
    required this.updatedDate,
  });

  final int conversationId;
  final int studentUserId;
  final String studentCode;
  final String studentFullName;
  final int? assignedToUserId;
  final String? assignedToFullName;
  final String subject;
  final int status;
  final String statusName;
  final int priority;
  final String priorityName;
  final String? lastMessagePreview;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime? closedAt;
  final DateTime? createdDate;
  final DateTime? updatedDate;

  bool get isClosed => status == 3;

  factory SupportConversationModel.fromJson(Map<String, dynamic> json) {
    return SupportConversationModel(
      conversationId: _SupportChatParser.parseInt(
        _readAny(json, const ['conversationID', 'conversationId']),
      ),
      studentUserId: _SupportChatParser.parseInt(
        _readAny(json, const ['studentUserID', 'studentUserId']),
      ),
      studentCode: json['studentCode']?.toString() ?? '',
      studentFullName: json['studentFullName']?.toString() ?? '',
      assignedToUserId: _SupportChatParser.parseNullableInt(
        _readAny(json, const ['assignedToUserID', 'assignedToUserId']),
      ),
      assignedToFullName: json['assignedToFullName']?.toString(),
      subject: json['subject']?.toString() ?? '',
      status: _SupportChatParser.parseInt(json['status'], defaultValue: 1),
      statusName: json['statusName']?.toString() ?? '',
      priority: _SupportChatParser.parseInt(json['priority'], defaultValue: 1),
      priorityName: json['priorityName']?.toString() ?? '',
      lastMessagePreview: json['lastMessagePreview']?.toString(),
      unreadCount: _SupportChatParser.parseInt(json['unreadCount']),
      lastMessageAt: _SupportChatParser.parseNullableDateTime(
        json['lastMessageAt'],
      ),
      closedAt: _SupportChatParser.parseNullableDateTime(json['closedAt']),
      createdDate: _SupportChatParser.parseNullableDateTime(
        json['createdDate'],
      ),
      updatedDate: _SupportChatParser.parseNullableDateTime(
        json['updatedDate'],
      ),
    );
  }
}

class SupportConversationPageModel {
  const SupportConversationPageModel({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<SupportConversationModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  factory SupportConversationPageModel.fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    if (data is Map) {
      return SupportConversationPageModel.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return SupportConversationPageModel.fromJson(json);
  }

  factory SupportConversationPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <SupportConversationModel>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(
            SupportConversationModel.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return SupportConversationPageModel(
      items: List<SupportConversationModel>.unmodifiable(items),
      totalCount: _SupportChatParser.parseInt(json['totalCount']),
      pageNumber: _SupportChatParser.parseInt(
        json['pageNumber'],
        defaultValue: 1,
      ),
      pageSize: _SupportChatParser.parseInt(json['pageSize'], defaultValue: 20),
      totalPages: _SupportChatParser.parseInt(
        json['totalPages'],
        defaultValue: 1,
      ),
      hasPreviousPage: _SupportChatParser.parseBool(json['hasPreviousPage']),
      hasNextPage: _SupportChatParser.parseBool(json['hasNextPage']),
    );
  }
}

Object? _readAny(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

class _SupportChatParser {
  static int parseInt(Object? raw, {int defaultValue = 0}) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim()) ?? defaultValue;
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
      return int.tryParse(raw.trim());
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

  static DateTime? parseNullableDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw.toString());
  }
}
