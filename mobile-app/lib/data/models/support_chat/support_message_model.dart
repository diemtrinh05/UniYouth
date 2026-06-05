class SupportMessageModel {
  const SupportMessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderUserId,
    required this.senderFullName,
    required this.senderCode,
    required this.messageType,
    required this.content,
    required this.attachmentUrl,
    required this.isMine,
    required this.createdDate,
  });

  final int messageId;
  final int conversationId;
  final int senderUserId;
  final String senderFullName;
  final String senderCode;
  final int messageType;
  final String content;
  final String? attachmentUrl;
  final bool isMine;
  final DateTime? createdDate;

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    return SupportMessageModel(
      messageId: _parseInt(_readAny(json, const ['messageID', 'messageId'])),
      conversationId: _parseInt(
        _readAny(json, const ['conversationID', 'conversationId']),
      ),
      senderUserId: _parseInt(
        _readAny(json, const ['senderUserID', 'senderUserId']),
      ),
      senderFullName: json['senderFullName']?.toString() ?? '',
      senderCode: json['senderCode']?.toString() ?? '',
      messageType: _parseInt(json['messageType'], defaultValue: 1),
      content: json['content']?.toString() ?? '',
      attachmentUrl: json['attachmentUrl']?.toString(),
      isMine: _parseBool(json['isMine']),
      createdDate: _parseNullableDateTime(json['createdDate']),
    );
  }
}

class SupportMessagePageModel {
  const SupportMessagePageModel({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<SupportMessageModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  factory SupportMessagePageModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return SupportMessagePageModel.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return SupportMessagePageModel.fromJson(json);
  }

  factory SupportMessagePageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <SupportMessageModel>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(
            SupportMessageModel.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return SupportMessagePageModel(
      items: List<SupportMessageModel>.unmodifiable(items),
      totalCount: _parseInt(json['totalCount']),
      pageNumber: _parseInt(json['pageNumber'], defaultValue: 1),
      pageSize: _parseInt(json['pageSize'], defaultValue: 100),
      totalPages: _parseInt(json['totalPages'], defaultValue: 1),
      hasPreviousPage: _parseBool(json['hasPreviousPage']),
      hasNextPage: _parseBool(json['hasNextPage']),
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

int _parseInt(Object? raw, {int defaultValue = 0}) {
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

bool _parseBool(Object? raw, {bool defaultValue = false}) {
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

DateTime? _parseNullableDateTime(Object? raw) {
  if (raw == null) {
    return null;
  }
  return DateTime.tryParse(raw.toString());
}
