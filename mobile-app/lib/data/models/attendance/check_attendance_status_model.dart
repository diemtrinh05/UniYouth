class CheckAttendanceStatusModel {
  const CheckAttendanceStatusModel({
    required this.eventId,
    required this.hasCheckedIn,
    required this.isValid,
    required this.invalidReason,
  });

  final int eventId;
  final bool hasCheckedIn;
  final bool? isValid;
  final String? invalidReason;

  factory CheckAttendanceStatusModel.fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      return CheckAttendanceStatusModel.fromJson(mapped);
    }

    // Fallback for backend returning payload without ApiResponseDto envelope.
    return CheckAttendanceStatusModel.fromJson(json);
  }

  factory CheckAttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    return CheckAttendanceStatusModel(
      eventId: _StatusParser.parseInt(json['eventId']),
      hasCheckedIn: _StatusParser.parseBool(json['hasCheckedIn']),
      isValid: _StatusParser.parseNullableBool(json['isValid']),
      invalidReason: json['invalidReason']?.toString(),
    );
  }
}

class _StatusParser {
  static int parseInt(Object? raw, {int defaultValue = 0}) {
    if (raw is int) {
      return raw;
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
}
