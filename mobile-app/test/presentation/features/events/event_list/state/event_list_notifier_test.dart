import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/domain/usecases/events/get_events_usecase.dart';
import 'package:uniyouth_app/presentation/features/events/event_list/state/event_list_notifier.dart';

void main() {
  group('EventListNotifier', () {
    test('syncInitial loads first page with default page size and eventId desc sorting', () async {
      final repository = _FakeEventsRepository()
        ..onGetEvents = ({required filter}) async {
          return EventListPageResult(
            items: <EventListItem>[_eventItem(id: 1)],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        };
      final notifier = EventListNotifier(
        getEventsUseCase: GetEventsUseCase(repository: repository),
      );

      await notifier.syncInitial();

      expect(repository.filters.length, 1);
      expect(repository.filters.first.pageSize, 10);
      expect(repository.filters.first.sortBy, 'eventId');
      expect(repository.filters.first.sortDir, 'desc');
      expect(notifier.state.items.length, 1);
      expect(notifier.state.isInitialLoading, isFalse);
    });

    test('loadMore is guarded when there is no next page', () async {
      final repository = _FakeEventsRepository()
        ..onGetEvents = ({required filter}) async {
          return EventListPageResult(
            items: <EventListItem>[_eventItem(id: 1)],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        };
      final notifier = EventListNotifier(
        getEventsUseCase: GetEventsUseCase(repository: repository),
      );

      await notifier.syncInitial();
      await notifier.loadMore();

      expect(repository.filters.length, 1);
      expect(notifier.state.items.length, 1);
    });

    test(
      'applyFilters keeps selected status and parses ids in syncInitial request',
      () async {
        final repository = _FakeEventsRepository()
          ..onGetEvents = ({required filter}) async {
            return EventListPageResult(
              items: <EventListItem>[_eventItem(id: 2)],
              totalCount: 1,
              pageNumber: 1,
              pageSize: filter.pageSize,
              totalPages: 1,
              hasPreviousPage: false,
              hasNextPage: false,
            );
          };
        final notifier = EventListNotifier(
          getEventsUseCase: GetEventsUseCase(repository: repository),
        );
        notifier.selectStatus(2);

        await notifier.applyFilters(
          eventTypeIdText: '12',
          instituteIdText: '34',
        );

        expect(repository.filters.length, 1);
        final appliedFilter = repository.filters.single;
        expect(appliedFilter.status, 2);
        expect(appliedFilter.sortBy, 'eventId');
        expect(appliedFilter.sortDir, 'desc');
        expect(appliedFilter.eventTypeId, 12);
        expect(appliedFilter.instituteId, 34);
        expect(notifier.state.status, 2);
        expect(notifier.state.eventTypeId, 12);
        expect(notifier.state.instituteId, 34);
      },
    );

    test('applyFilters sets eventId desc sorting even without selected status', () async {
      final repository = _FakeEventsRepository()
        ..onGetEvents = ({required filter}) async {
          return EventListPageResult(
            items: <EventListItem>[_eventItem(id: 3)],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        };
      final notifier = EventListNotifier(
        getEventsUseCase: GetEventsUseCase(repository: repository),
      );

      await notifier.applyFilters(
        eventTypeIdText: '12',
        instituteIdText: '',
      );

      final appliedFilter = repository.filters.single;
      expect(appliedFilter.status, isNull);
      expect(appliedFilter.sortBy, 'eventId');
      expect(appliedFilter.sortDir, 'desc');
      expect(notifier.state.sortBy, 'eventId');
      expect(notifier.state.sortDir, 'desc');
    });

    test(
      'applyFilters throws FormatException when startDate is after endDate',
      () async {
        final notifier = EventListNotifier(
          getEventsUseCase: GetEventsUseCase(
            repository: _FakeEventsRepository(),
          ),
        );
        notifier.setStartDate(DateTime(2026, 2, 10));
        notifier.setEndDate(DateTime(2026, 2, 9));

        expect(
          () => notifier.applyFilters(eventTypeIdText: '', instituteIdText: ''),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'syncInitial sets error message when usecase throws AppError',
      () async {
        final repository = _FakeEventsRepository()
          ..onGetEvents = ({required filter}) async {
            throw const AppError(
              type: AppErrorType.network,
              message: 'Network error.',
            );
          };
        final notifier = EventListNotifier(
          getEventsUseCase: GetEventsUseCase(repository: repository),
        );

        await notifier.syncInitial();

        expect(notifier.state.errorMessage, isNotNull);
        expect(notifier.state.isInitialLoading, isFalse);
      },
    );

    test('clearFilters clears selected status', () async {
      final notifier = EventListNotifier(
        getEventsUseCase: GetEventsUseCase(repository: _FakeEventsRepository()),
      );

      notifier.selectStatus(3);
      await notifier.clearFilters();

      expect(notifier.state.status, isNull);
      expect(notifier.state.sortBy, 'eventId');
      expect(notifier.state.sortDir, 'desc');
    });

    test('search sends q to repository filter and stores trimmed query', () async {
      final repository = _FakeEventsRepository()
        ..onGetEvents = ({required filter}) async {
          return EventListPageResult(
            items: <EventListItem>[_eventItem(id: 4)],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        };
      final notifier = EventListNotifier(
        getEventsUseCase: GetEventsUseCase(repository: repository),
      );

      await notifier.search('  hoi thao  ');

      expect(repository.filters.single.q, 'hoi thao');
      expect(notifier.state.query, 'hoi thao');
      expect(notifier.state.items.length, 1);
    });
  });
}

class _FakeEventsRepository implements EventsRepository {
  final List<EventListFilter> filters = <EventListFilter>[];

  Future<EventListPageResult> Function({required EventListFilter filter})?
  onGetEvents;

  @override
  Future<EventListPageResult> getEvents({
    required EventListFilter filter,
  }) async {
    filters.add(filter);
    final override = onGetEvents;
    if (override != null) {
      return override(filter: filter);
    }
    return EventListPageResult(
      items: const <EventListItem>[],
      totalCount: 0,
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }
}

EventListItem _eventItem({required int id}) {
  return EventListItem(
    eventId: id,
    eventName: 'Event $id',
    description: null,
    startTime: DateTime(2026, 1, 1, 8),
    endTime: DateTime(2026, 1, 1, 10),
    locationName: 'Hall A',
    maxParticipants: 100,
    currentParticipants: 10,
    status: 1,
    statusName: 'Open',
    eventTypeName: 'Workshop',
    instituteName: 'Institute',
    registrationDeadline: DateTime(2025, 12, 31),
    thumbnailUrl: null,
    hasAvailableSlots: true,
  );
}
