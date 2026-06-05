import 'get_events_usecase.dart';

class HomeEventPreviewItem {
  const HomeEventPreviewItem({
    required this.eventId,
    required this.eventName,
    required this.startTime,
    required this.status,
    required this.statusName,
    required this.thumbnailUrl,
    required this.hasAvailableSlots,
  });

  final int eventId;
  final String eventName;
  final DateTime startTime;
  final int status;
  final String? statusName;
  final String? thumbnailUrl;
  final bool hasAvailableSlots;
}

class GetHomeEventPreviewUseCase {
  const GetHomeEventPreviewUseCase({
    required EventsRepository repository,
    this.previewItemCount = 3,
  }) : _repository = repository;

  final EventsRepository _repository;
  final int previewItemCount;

  Future<List<HomeEventPreviewItem>> call() async {
    final result = await _repository.getEvents(
      filter: EventListFilter(
        pageNumber: 1,
        pageSize: previewItemCount,
        sortBy: 'eventId',
        sortDir: 'desc',
      ),
    );

    return result.items
        .map(
          (item) => HomeEventPreviewItem(
            eventId: item.eventId,
            eventName: item.eventName,
            startTime: item.startTime,
            status: item.status,
            statusName: item.statusName,
            thumbnailUrl: item.thumbnailUrl,
            hasAvailableSlots: item.hasAvailableSlots,
          ),
        )
        .toList(growable: false);
  }
}
