class CheckInRequirementsModel {
  const CheckInRequirementsModel({
    required this.eventId,
    required this.eventName,
    required this.enableFaceVerification,
  });

  final int eventId;
  final String eventName;
  final bool enableFaceVerification;

  factory CheckInRequirementsModel.fromApiResponse(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? json;
    return CheckInRequirementsModel(
      eventId: _RequirementsParser.parseInt(data['eventId']),
      eventName: _RequirementsParser.parseString(data['eventName']),
      enableFaceVerification: _RequirementsParser.parseBool(
        data['enableFaceVerification'],
      ),
    );
  }
}

final class _RequirementsParser {
  static int parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String parseString(Object? value) => value?.toString() ?? '';

  static bool parseBool(Object? value) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
