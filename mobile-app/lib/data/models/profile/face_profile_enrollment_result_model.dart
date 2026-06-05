class FaceProfileEnrollmentResultModel {
  const FaceProfileEnrollmentResultModel({
    required this.imageUrl,
    required this.message,
    required this.qualityScore,
  });

  final String? imageUrl;
  final String? message;
  final double? qualityScore;

  factory FaceProfileEnrollmentResultModel.fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      return FaceProfileEnrollmentResultModel.fromJson(
        mapped,
        fallbackMessage: json['message']?.toString(),
      );
    }

    if (_looksLikePayload(json)) {
      return FaceProfileEnrollmentResultModel.fromJson(json);
    }

    throw const FormatException(
      'Invalid face profile enrollment response payload.',
    );
  }

  factory FaceProfileEnrollmentResultModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackMessage,
  }) {
    return FaceProfileEnrollmentResultModel(
      imageUrl: json['imageUrl']?.toString(),
      message: json['message']?.toString() ?? fallbackMessage,
      qualityScore: _parseNullableDouble(json['qualityScore']),
    );
  }

  static bool _looksLikePayload(Map<String, dynamic> json) {
    return json.containsKey('imageUrl') ||
        json.containsKey('qualityScore') ||
        json.containsKey('message');
  }

  static double? _parseNullableDouble(Object? raw) {
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
