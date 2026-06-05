class EventListFilter {
  const EventListFilter({
    this.pageNumber = 1,
    this.pageSize = 10,
    this.q,
    this.status,
    this.sortBy,
    this.sortDir,
    this.eventTypeId,
    this.instituteId,
    this.startDate,
    this.endDate,
  });

  final int pageNumber;
  final int pageSize;
  final String? q;
  final int? status;
  final String? sortBy;
  final String? sortDir;
  final int? eventTypeId;
  final int? instituteId;
  final DateTime? startDate;
  final DateTime? endDate;
}

class EventListItem {
  const EventListItem({
    required this.eventId,
    required this.eventName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    required this.statusName,
    required this.eventTypeName,
    required this.instituteName,
    required this.registrationDeadline,
    required this.thumbnailUrl,
    required this.hasAvailableSlots,
  });

  final int eventId;
  final String eventName;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? locationName;
  final int? maxParticipants;
  final int? currentParticipants;
  final int status;
  final String? statusName;
  final String? eventTypeName;
  final String? instituteName;
  final DateTime? registrationDeadline;
  final String? thumbnailUrl;
  final bool hasAvailableSlots;
}

class EventListPageResult {
  const EventListPageResult({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<EventListItem> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
}

abstract class EventsRepository {
  Future<EventListPageResult> getEvents({required EventListFilter filter});
}

class GetEventsUseCase {
  const GetEventsUseCase({required EventsRepository repository})
    : _repository = repository;

  final EventsRepository _repository;

  // Use case điều phối filter + phân trang, UI không truy cập repository trực tiếp.
  Future<EventListPageResult> call({required EventListFilter filter}) {
    return _repository.getEvents(filter: filter);
  }
}
