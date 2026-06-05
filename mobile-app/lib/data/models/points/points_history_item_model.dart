class PointsHistoryItemModel {
  const PointsHistoryItemModel({
    required this.pointId,
    required this.eventId,
    required this.eventName,
    required this.eventStartTime,
    required this.points,
    required this.pointType,
    required this.roleType,
    required this.awardedByName,
    required this.createdDate,
  });

  final int pointId;
  final int eventId;
  final String? eventName;
  final DateTime? eventStartTime;
  final int points;
  final String? pointType;
  final String? roleType;
  final String? awardedByName;
  final DateTime? createdDate;

  factory PointsHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return PointsHistoryItemModel(
      pointId: _PointsHistoryParser.parseInt(
        _readAny(json, const <String>['pointID', 'pointId']),
      ),
      eventId: _PointsHistoryParser.parseInt(
        _readAny(json, const <String>['eventID', 'eventId']),
      ),
      eventName: json['eventName']?.toString(),
      eventStartTime: _PointsHistoryParser.parseNullableDateTime(
        json['eventStartTime'],
      ),
      points: _PointsHistoryParser.parseInt(json['points']),
      pointType: json['pointType']?.toString(),
      roleType: json['roleType']?.toString(),
      awardedByName: json['awardedByName']?.toString(),
      createdDate: _PointsHistoryParser.parseNullableDateTime(
        json['createdDate'],
      ),
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

class PointsHistoryPageModel {
  const PointsHistoryPageModel({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<PointsHistoryItemModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  factory PointsHistoryPageModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final mappedData = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return PointsHistoryPageModel.fromJson(mappedData);
    }

    return PointsHistoryPageModel.fromJson(json);
  }

  factory PointsHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsedItems = <PointsHistoryItemModel>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          final mappedItem = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          parsedItems.add(PointsHistoryItemModel.fromJson(mappedItem));
        }
      }
    }

    return PointsHistoryPageModel(
      items: List<PointsHistoryItemModel>.unmodifiable(parsedItems),
      totalCount: _PointsHistoryParser.parseInt(json['totalCount']),
      pageNumber: _PointsHistoryParser.parseInt(
        json['pageNumber'],
        defaultValue: 1,
      ),
      pageSize: _PointsHistoryParser.parseInt(
        json['pageSize'],
        defaultValue: 20,
      ),
      totalPages: _PointsHistoryParser.parseInt(
        json['totalPages'],
        defaultValue: 1,
      ),
      hasPreviousPage: _PointsHistoryParser.parseBool(json['hasPreviousPage']),
      hasNextPage: _PointsHistoryParser.parseBool(json['hasNextPage']),
    );
  }
}

class _PointsHistoryParser {
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

    final parsed = DateTime.tryParse(raw.toString());
    return parsed;
  }
}
