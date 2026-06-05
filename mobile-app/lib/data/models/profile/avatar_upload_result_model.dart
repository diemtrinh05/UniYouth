class AvatarUploadResultModel {
  const AvatarUploadResultModel({
    required this.avatarUrl,
    required this.message,
  });

  final String? avatarUrl;
  final String? message;

  factory AvatarUploadResultModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      return AvatarUploadResultModel.fromJson(mapped);
    }

    if (_looksLikePayload(json)) {
      return AvatarUploadResultModel.fromJson(json);
    }

    throw const FormatException('Invalid avatar upload response payload.');
  }

  factory AvatarUploadResultModel.fromJson(Map<String, dynamic> json) {
    return AvatarUploadResultModel(
      avatarUrl: json['avatarUrl']?.toString(),
      message: json['message']?.toString(),
    );
  }

  static bool _looksLikePayload(Map<String, dynamic> json) {
    return json.containsKey('avatarUrl') || json.containsKey('message');
  }
}
