class EventDetailTypeInfo {
  const EventDetailTypeInfo({
    required this.typeId,
    required this.typeName,
    required this.description,
  });

  final int typeId;
  final String? typeName;
  final String? description;
}

class EventDetailInstituteInfo {
  const EventDetailInstituteInfo({
    required this.instituteId,
    required this.instituteName,
  });

  final int instituteId;
  final String? instituteName;
}

class EventDetailImage {
  const EventDetailImage({
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
}

class EventDetail {
  const EventDetail({
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
  final EventDetailTypeInfo? eventType;
  final EventDetailInstituteInfo? institute;
  final DateTime? registrationDeadline;
  final List<EventDetailImage> images;
  final String? createdByName;
  final DateTime? createdDate;
  final bool hasAvailableSlots;
  final bool isRegistrationClosed;
  final bool enableFaceVerification;
}

abstract class EventDetailRepository {
  Future<EventDetail> getEventDetail({required int eventId});
}

class GetEventDetailUseCase {
  const GetEventDetailUseCase({required EventDetailRepository repository})
    : _repository = repository;

  final EventDetailRepository _repository;

  // Use case exposes event detail for UI while keeping data layer hidden.
  Future<EventDetail> call({required int eventId}) {
    return _repository.getEventDetail(eventId: eventId);
  }
}
