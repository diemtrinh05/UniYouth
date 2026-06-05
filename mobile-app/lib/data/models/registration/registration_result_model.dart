class RegistrationResultModel {
  const RegistrationResultModel({
    required this.registrationId,
    required this.eventId,
    required this.eventName,
    required this.userId,
    required this.userFullName,
    required this.registerTime,
    required this.status,
    required this.cancellationReason,
    required this.createdDate,
  });

  final int registrationId;
  final int eventId;
  final String? eventName;
  final int userId;
  final String? userFullName;
  final DateTime? registerTime;
  final String? status;
  final String? cancellationReason;
  final DateTime? createdDate;

  factory RegistrationResultModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid my registration response payload.');
    }

    final typedData = data.map((key, value) => MapEntry(key.toString(), value));
    return RegistrationResultModel.fromJson(typedData);
  }

  factory RegistrationResultModel.fromJson(Map<String, dynamic> json) {
    return RegistrationResultModel(
      registrationId: _RegistrationParser.parseInt(json['registrationID']),
      eventId: _RegistrationParser.parseInt(json['eventID']),
      eventName: json['eventName']?.toString(),
      userId: _RegistrationParser.parseInt(json['userID']),
      userFullName: json['userFullName']?.toString(),
      registerTime: _RegistrationParser.parseNullableDateTime(
        json['registerTime'],
      ),
      status: json['status']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      createdDate: _RegistrationParser.parseNullableDateTime(
        json['createdDate'],
      ),
    );
  }
}

class _RegistrationParser {
  static int parseInt(Object? raw, {int defaultValue = 0}) {
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw) ?? defaultValue;
    }
    return defaultValue;
  }

  static DateTime? parseNullableDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    final value = DateTime.tryParse(raw.toString());
    return value;
  }
}
