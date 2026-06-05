class CheckInResultModel {
  const CheckInResultModel({
    required this.isSuccess,
    required this.message,
    required this.eventName,
    required this.checkInTime,
    required this.distance,
    required this.isValid,
    required this.invalidReason,
    required this.attendanceId,
    required this.pointsAwarded,
    required this.faceVerified,
    required this.faceConfidence,
    required this.faceVerificationStatus,
    required this.faceVerificationMessage,
    required this.riskScore,
    required this.riskLevel,
  });

  final bool isSuccess;
  final String? message;
  final String? eventName;
  final DateTime? checkInTime;
  final double? distance;
  final bool isValid;
  final String? invalidReason;
  final int? attendanceId;
  final PointAwardedModel? pointsAwarded;
  final bool? faceVerified;
  final double? faceConfidence;
  final String? faceVerificationStatus;
  final String? faceVerificationMessage;
  final int? riskScore;
  final String? riskLevel;

  factory CheckInResultModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      return CheckInResultModel.fromJson(mapped);
    }

    if (_looksLikeCheckInPayload(json)) {
      return CheckInResultModel.fromJson(json);
    }

    throw const FormatException('Invalid check-in response payload.');
  }

  factory CheckInResultModel.fromJson(Map<String, dynamic> json) {
    final pointsAwardedRaw = json['pointsAwarded'];

    return CheckInResultModel(
      isSuccess: _CheckInParser.parseBool(json['isSuccess']),
      message: json['message']?.toString(),
      eventName: json['eventName']?.toString(),
      checkInTime: _CheckInParser.parseNullableDateTime(json['checkInTime']),
      distance: _CheckInParser.parseNullableDouble(json['distance']),
      isValid: _CheckInParser.parseBool(json['isValid']),
      invalidReason: json['invalidReason']?.toString(),
      attendanceId: _CheckInParser.parseNullableInt(
        _readAny(json, const <String>['attendanceID', 'attendanceId']),
      ),
      faceVerified: _CheckInParser.parseNullableBool(json['faceVerified']),
      faceConfidence: _CheckInParser.parseNullableDouble(
        json['faceConfidence'],
      ),
      faceVerificationStatus: json['faceVerificationStatus']?.toString(),
      faceVerificationMessage: json['faceVerificationMessage']?.toString(),
      riskScore: _CheckInParser.parseNullableInt(json['riskScore']),
      riskLevel: json['riskLevel']?.toString(),
      pointsAwarded: pointsAwardedRaw is Map
          ? PointAwardedModel.fromJson(
              pointsAwardedRaw.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : null,
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

  static bool _looksLikeCheckInPayload(Map<String, dynamic> json) {
    return json.containsKey('isValid') ||
        json.containsKey('invalidReason') ||
        json.containsKey('pointsAwarded') ||
        json.containsKey('distance') ||
        json.containsKey('faceVerificationStatus') ||
        json.containsKey('riskLevel');
  }
}

class PointAwardedModel {
  const PointAwardedModel({
    required this.points,
    required this.pointType,
    required this.roleType,
    required this.currentTotalPoints,
  });

  final int? points;
  final String? pointType;
  final String? roleType;
  final int? currentTotalPoints;

  factory PointAwardedModel.fromJson(Map<String, dynamic> json) {
    return PointAwardedModel(
      points: _CheckInParser.parseNullableInt(json['points']),
      pointType: json['pointType']?.toString(),
      roleType: json['roleType']?.toString(),
      currentTotalPoints: _CheckInParser.parseNullableInt(
        json['currentTotalPoints'],
      ),
    );
  }
}

class _CheckInParser {
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

  static DateTime? parseNullableDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    final parsed = DateTime.tryParse(raw.toString());
    return parsed;
  }
}
