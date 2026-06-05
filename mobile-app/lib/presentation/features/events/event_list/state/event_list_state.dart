import '../../../../../../domain/usecases/events/get_events_usecase.dart';

class EventListState {
  const EventListState({
    this.items = const <EventListItem>[],
    this.totalCount = 0,
    this.currentPage = 1,
    this.pageSize = 10,
    this.totalPages = 1,
    this.hasPreviousPage = false,
    this.hasNextPage = false,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.query,
    this.status,
    this.sortBy = 'eventId',
    this.sortDir = 'desc',
    this.eventTypeId,
    this.instituteId,
    this.startDate,
    this.endDate,
    this.errorMessage,
  });

  final List<EventListItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? query;
  final int? status;
  final String? sortBy;
  final String? sortDir;
  final int? eventTypeId;
  final int? instituteId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? errorMessage;

  bool get hasActiveFilter =>
      query != null && query!.trim().isNotEmpty ||
      status != null ||
      eventTypeId != null ||
      instituteId != null ||
      startDate != null ||
      endDate != null;

  bool get isEmpty => items.isEmpty;

  EventListState copyWith({
    List<EventListItem>? items,
    int? totalCount,
    int? currentPage,
    int? pageSize,
    int? totalPages,
    bool? hasPreviousPage,
    bool? hasNextPage,
    bool? isInitialLoading,
    bool? isLoadingMore,
    String? query,
    bool clearQuery = false,
    int? status,
    bool clearStatus = false,
    String? sortBy,
    bool clearSortBy = false,
    String? sortDir,
    bool clearSortDir = false,
    int? eventTypeId,
    bool clearEventTypeId = false,
    int? instituteId,
    bool clearInstituteId = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return EventListState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      query: clearQuery ? null : (query ?? this.query),
      status: clearStatus ? null : (status ?? this.status),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      sortDir: clearSortDir ? null : (sortDir ?? this.sortDir),
      eventTypeId: clearEventTypeId ? null : (eventTypeId ?? this.eventTypeId),
      instituteId: clearInstituteId ? null : (instituteId ?? this.instituteId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
