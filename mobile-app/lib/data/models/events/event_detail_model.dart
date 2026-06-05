class EventTypeInfoModel {
  const EventTypeInfoModel({
    required this.typeId,
    required this.typeName,
    required this.description,
  });

  final int typeId;
  final String? typeName;
  final String? description;

  factory EventTypeInfoModel.fromJson(Map<String, dynamic> json) {
    return EventTypeInfoModel(
      typeId: _EventDetailParser.parseInt(json['typeId']),
      typeName: json['typeName']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class InstituteInfoModel {
  const InstituteInfoModel({
    required this.instituteId,
    required this.instituteName,
  });

  final int instituteId;
  final String? instituteName;

  factory InstituteInfoModel.fromJson(Map<String, dynamic> json) {
    return InstituteInfoModel(
      instituteId: _EventDetailParser.parseInt(json['instituteId']),
      instituteName: json['instituteName']?.toString(),
    );
  }
}

class EventImageModel {
  const EventImageModel({
    required this.imageId,
    required this.imageUrl,
    required this.imageType,
    required this.caption,
    required this.displayOrder,
  });

  final int imageId;
  final String? imageUrl;
  final String? imageType;
  final String? caption;
  final int? displayOrder;

  factory EventImageModel.fromJson(Map<String, dynamic> json) {
    return EventImageModel(
      imageId: _EventDetailParser.parseInt(json['imageId']),
      imageUrl: json['imageUrl']?.toString(),
      imageType: json['imageType']?.toString(),
      caption: json['caption']?.toString(),
      displayOrder: _EventDetailParser.parseNullableInt(json['displayOrder']),
    );
  }
}

class EventDetailModel {
  const EventDetailModel({
    required this.eventId,
    required this.eventName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.allowRadius,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    required this.statusName,
    required this.eventType,
    required this.institute,
    required this.registrationDeadline,
    required this.images,
    required this.createdByName,
    required this.createdDate,
    required this.hasAvailableSlots,
    required this.isRegistrationClosed,
    required this.enableFaceVerification,
  });

  final int eventId;
  final String eventName;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int? allowRadius;
  final int? maxParticipants;
  final int? currentParticipants;
  final int status;
  final String? statusName;
  final EventTypeInfoModel? eventType;
  final InstituteInfoModel? institute;
  final DateTime? registrationDeadline;
  final List<EventImageModel> images;
  final String? createdByName;
  final DateTime? createdDate;
  final bool hasAvailableSlots;
  final bool isRegistrationClosed;
  final bool enableFaceVerification;

  factory EventDetailModel.fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map) {
      throw const FormatException('Invalid event detail payload.');
    }
    final typedData = data.map((key, value) => MapEntry(key.toString(), value));
    return EventDetailModel.fromJson(typedData);
  }

  factory EventDetailModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final parsedImages = <EventImageModel>[];

    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is Map) {
          final mappedItem = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          parsedImages.add(EventImageModel.fromJson(mappedItem));
        }
      }
    }

    final rawEventType = json['eventType'];
    final rawInstitute = json['institute'];

    return EventDetailModel(
      eventId: _EventDetailParser.parseInt(json['eventId']),
      eventName: (json['eventName']?.toString() ?? '').trim(),
      description: json['description']?.toString(),
      startTime: _EventDetailParser.parseDateTime(json['startTime']),
      endTime: _EventDetailParser.parseDateTime(json['endTime']),
      locationName: json['locationName']?.toString(),
      latitude: _EventDetailParser.parseNullableDouble(json['latitude']),
      longitude: _EventDetailParser.parseNullableDouble(json['longitude']),
      allowRadius: _EventDetailParser.parseNullableInt(json['allowRadius']),
      maxParticipants: _EventDetailParser.parseNullableInt(
        json['maxParticipants'],
      ),
      currentParticipants: _EventDetailParser.parseNullableInt(
        json['currentParticipants'],
      ),
      status: _EventDetailParser.parseInt(json['status']),
      statusName: json['statusName']?.toString(),
      eventType: rawEventType is Map
          ? EventTypeInfoModel.fromJson(
              rawEventType.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
      institute: rawInstitute is Map
          ? InstituteInfoModel.fromJson(
              rawInstitute.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
      registrationDeadline: _EventDetailParser.parseNullableDateTime(
        json['registrationDeadline'],
      ),
      images: List<EventImageModel>.unmodifiable(parsedImages),
      createdByName: json['createdByName']?.toString(),
      createdDate: _EventDetailParser.parseNullableDateTime(
        json['createdDate'],
      ),
      hasAvailableSlots: _EventDetailParser.parseBool(
        json['hasAvailableSlots'],
      ),
      isRegistrationClosed: _EventDetailParser.parseBool(
        json['isRegistrationClosed'],
      ),
      enableFaceVerification: _EventDetailParser.parseBool(
        json['enableFaceVerification'],
      ),
    );
  }
}

class _EventDetailParser {
  static int parseInt(Object? raw, {int defaultValue = 0}) {
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw) ?? defaultValue;
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
    if (raw is int) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw);
    }
    return null;
  }

  static bool parseBool(Object? raw, {bool defaultValue = false}) {
    if (raw is bool) {
      return raw;
    }
    if (raw is String) {
      final value = raw.trim().toLowerCase();
      if (value == 'true') {
        return true;
      }
      if (value == 'false') {
        return false;
      }
    }
    return defaultValue;
  }

  static DateTime parseDateTime(Object? raw) {
    final value = DateTime.tryParse(raw?.toString() ?? '');
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return value;
  }

  static DateTime? parseNullableDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    final value = DateTime.tryParse(raw.toString());
    return value;
  }
}
