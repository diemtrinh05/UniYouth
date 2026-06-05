class AttendanceHistoryItemModel {
  const AttendanceHistoryItemModel({
    required this.attendanceId,
    required this.checkInTime,
    required this.checkInMethod,
    required this.isValid,
    required this.invalidReason,
    required this.distance,
    required this.eventName,
    required this.hasAttendancePointsAwarded,
    required this.attendancePointId,
  });

  final int attendanceId;
  final DateTime? checkInTime;
  final String? checkInMethod;
  final bool? isValid;
  final String? invalidReason;
  final double? distance;
  final String? eventName;
  final bool hasAttendancePointsAwarded;
  final int? attendancePointId;

  factory AttendanceHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItemModel(
      attendanceId: _HistoryParser.parseInt(
        _readAny(json, const <String>['attendanceID', 'attendanceId']),
      ),
      checkInTime: _HistoryParser.parseNullableDateTime(json['checkInTime']),
      checkInMethod: json['checkInMethod']?.toString(),
      isValid: _HistoryParser.parseNullableBool(json['isValid']),
      invalidReason: json['invalidReason']?.toString(),
      distance: _HistoryParser.parseNullableDouble(json['distance']),
      eventName: _readAny(json, const <String>[
        'eventName',
        'eventTitle',
      ])?.toString(),
      hasAttendancePointsAwarded: _HistoryParser.parseBool(
        _readAny(json, const <String>['hasAttendancePointsAwarded']),
      ),
      attendancePointId: _HistoryParser.parseNullableInt(
        _readAny(json, const <String>['attendancePointID', 'attendancePointId']),
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

class AttendanceHistoryPageModel {
  const AttendanceHistoryPageModel({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<AttendanceHistoryItemModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  factory AttendanceHistoryPageModel.fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    if (data is Map) {
      final mappedData = data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return AttendanceHistoryPageModel.fromJson(mappedData);
    }

    // Fallback for endpoints that may return a wrapper with `attendances`.
    final attendances = json['attendances'];
    if (attendances is Map) {
      final mappedData = attendances.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return AttendanceHistoryPageModel.fromJson(mappedData);
    }

    return AttendanceHistoryPageModel.fromJson(json);
  }

  factory AttendanceHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsedItems = <AttendanceHistoryItemModel>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          final mapped = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          parsedItems.add(AttendanceHistoryItemModel.fromJson(mapped));
        }
      }
    }

    return AttendanceHistoryPageModel(
      items: List<AttendanceHistoryItemModel>.unmodifiable(parsedItems),
      totalCount: _HistoryParser.parseInt(json['totalCount']),
      pageNumber: _HistoryParser.parseInt(json['pageNumber'], defaultValue: 1),
      pageSize: _HistoryParser.parseInt(json['pageSize'], defaultValue: 20),
      totalPages: _HistoryParser.parseInt(json['totalPages'], defaultValue: 1),
      hasPreviousPage: _HistoryParser.parseBool(json['hasPreviousPage']),
      hasNextPage: _HistoryParser.parseBool(json['hasNextPage']),
    );
  }
}

class _HistoryParser {
  static int parseInt(Object? raw, {int defaultValue = 0}) {
    if (raw is int) {
      return raw;
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
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  static double? parseNullableDouble(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is double) {
      return raw;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw);
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
