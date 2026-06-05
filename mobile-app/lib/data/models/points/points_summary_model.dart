class PointsSummaryModel {
  const PointsSummaryModel({
    required this.totalPoints,
    required this.eventsParticipated,
    required this.validAttendances,
    required this.fullName,
    required this.code,
  });

  final int totalPoints;
  final int eventsParticipated;
  final int validAttendances;
  final String? fullName;
  final String? code;

  factory PointsSummaryModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      return PointsSummaryModel.fromJson(mapped);
    }

    if (_looksLikeSummaryPayload(json)) {
      return PointsSummaryModel.fromJson(json);
    }

    throw const FormatException('Invalid points summary response payload.');
  }

  factory PointsSummaryModel.fromJson(Map<String, dynamic> json) {
    return PointsSummaryModel(
      totalPoints: _PointsSummaryParser.parseInt(json['totalPoints']),
      eventsParticipated: _PointsSummaryParser.parseInt(
        json['eventsParticipated'],
      ),
      validAttendances: _PointsSummaryParser.parseInt(json['validAttendances']),
      fullName: json['fullName']?.toString(),
      code: json['code']?.toString(),
    );
  }

  static bool _looksLikeSummaryPayload(Map<String, dynamic> json) {
    return json.containsKey('totalPoints') ||
        json.containsKey('eventsParticipated') ||
        json.containsKey('validAttendances');
  }
}

class _PointsSummaryParser {
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
}

