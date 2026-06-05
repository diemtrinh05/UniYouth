class MyProfileModel {
  const MyProfileModel({
    required this.userId,
    required this.code,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.role,
    required this.unitName,
    required this.unitId,
    required this.positionId,
    required this.joinDate,
    required this.position,
    required this.instituteName,
    required this.instituteId,
    required this.status,
    required this.lastLoginDate,
    required this.createdDate,
    this.hasActiveFaceProfile = false,
    this.faceProfileImageUrl,
    this.faceProfileUpdatedDate,
    this.faceProfileQualityScore,
  });

  final int userId;
  final String? code;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final bool? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? role;
  final String? unitName;
  final int? unitId;
  final int? positionId;
  final DateTime? joinDate;
  final String? position;
  final String? instituteName;
  final int? instituteId;
  final int? status;
  final DateTime? lastLoginDate;
  final DateTime? createdDate;
  final bool hasActiveFaceProfile;
  final String? faceProfileImageUrl;
  final DateTime? faceProfileUpdatedDate;
  final double? faceProfileQualityScore;

  factory MyProfileModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      return MyProfileModel.fromJson(mapped);
    }

    if (_looksLikeProfilePayload(json)) {
      return MyProfileModel.fromJson(json);
    }

    throw const FormatException('Invalid profile response payload.');
  }

  factory MyProfileModel.fromJson(Map<String, dynamic> json) {
    return MyProfileModel(
      userId: _ProfileParser.parseInt(json['userId']),
      code: json['code']?.toString(),
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      gender: _ProfileParser.parseNullableBool(json['gender']),
      dateOfBirth: _ProfileParser.parseNullableDateTime(json['dateOfBirth']),
      address: json['address']?.toString(),
      role: json['role']?.toString(),
      unitName: json['unitName']?.toString(),
      unitId: _ProfileParser.parseNullableInt(json['unitId']),
      positionId: _ProfileParser.parseNullableInt(json['positionId']),
      joinDate: _ProfileParser.parseNullableDateTime(json['joinDate']),
      position: json['position']?.toString(),
      instituteName: json['instituteName']?.toString(),
      instituteId: _ProfileParser.parseNullableInt(json['instituteId']),
      status: _ProfileParser.parseNullableInt(json['status']),
      lastLoginDate: _ProfileParser.parseNullableDateTime(
        json['lastLoginDate'],
      ),
      createdDate: _ProfileParser.parseNullableDateTime(json['createdDate']),
      hasActiveFaceProfile:
          _ProfileParser.parseNullableBool(json['hasActiveFaceProfile']) ??
          false,
      faceProfileImageUrl: json['faceProfileImageUrl']?.toString(),
      faceProfileUpdatedDate: _ProfileParser.parseNullableDateTime(
        json['faceProfileUpdatedDate'],
      ),
      faceProfileQualityScore: _ProfileParser.parseNullableDouble(
        json['faceProfileQualityScore'],
      ),
    );
  }

  static bool _looksLikeProfilePayload(Map<String, dynamic> json) {
    return json.containsKey('userId') ||
        json.containsKey('code') ||
        json.containsKey('fullName') ||
        json.containsKey('email');
  }
}

class _ProfileParser {
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
      return double.tryParse(raw.trim());
    }
    return null;
  }
}
