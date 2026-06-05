class ChangePasswordResultModel {
  const ChangePasswordResultModel({
    required this.success,
    required this.message,
    required this.additionalInfo,
  });

  final bool success;
  final String? message;
  final String? additionalInfo;

  factory ChangePasswordResultModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      return ChangePasswordResultModel.fromJson(mapped);
    }

    if (_looksLikePayload(json)) {
      return ChangePasswordResultModel.fromJson(json);
    }

    throw const FormatException('Invalid change password response payload.');
  }

  factory ChangePasswordResultModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResultModel(
      success: _parseBool(json['success'], defaultValue: true),
      message: json['message']?.toString(),
      additionalInfo: json['additionalInfo']?.toString(),
    );
  }

  static bool _looksLikePayload(Map<String, dynamic> json) {
    return json.containsKey('success') ||
        json.containsKey('message') ||
        json.containsKey('additionalInfo');
  }

  static bool _parseBool(Object? raw, {required bool defaultValue}) {
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
}
