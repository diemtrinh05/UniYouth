class EventTypeModel {
  const EventTypeModel({
    required this.typeId,
    required this.typeName,
    required this.description,
  });

  final int typeId;
  final String typeName;
  final String? description;

  factory EventTypeModel.fromJson(Map<String, dynamic> json) {
    // Parse linh hoạt để chịu được response trả về number hoặc string.
    return EventTypeModel(
      typeId: _parseTypeId(json['typeId']),
      typeName: (json['typeName']?.toString() ?? '').trim(),
      description: json['description']?.toString(),
    );
  }

  static int _parseTypeId(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw) ?? 0;
    }
    return 0;
  }
}
