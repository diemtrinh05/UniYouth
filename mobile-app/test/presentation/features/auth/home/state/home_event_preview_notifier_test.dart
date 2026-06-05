import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/domain/usecases/events/get_events_usecase.dart';
import 'package:uniyouth_app/domain/usecases/events/get_home_event_preview_usecase.dart';
import 'package:uniyouth_app/presentation/features/auth/home/state/home_event_preview_notifier.dart';

void main() {
  group('HomeEventPreviewNotifier', () {
    test('loadPreview maps backend items to home preview state', () async {
      final notifier = HomeEventPreviewNotifier(
        getHomeEventPreviewUseCase: GetHomeEventPreviewUseCase(
          repository: _FakeEventsRepository(),
        ),
      );
      addTearDown(notifier.dispose);

      await notifier.loadPreview();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.eventId, 11);
      expect(notifier.state.items.first.eventName, 'Sự kiện A');
    });

    test('loadPreview exposes readable error when api fails', () async {
      final notifier = HomeEventPreviewNotifier(
        getHomeEventPreviewUseCase: GetHomeEventPreviewUseCase(
          repository: _FakeEventsRepository(
            error: const AppError(
              type: AppErrorType.badRequest,
              statusCode: 400,
              message: 'Không tải được danh sách sự kiện',
              isBackendMessage: true,
            ),
          ),
        ),
      );
      addTearDown(notifier.dispose);

      await notifier.loadPreview();

      expect(notifier.state.isLoading, isFalse);
      expect(
        notifier.state.errorMessage,
        contains('Không tải được danh sách sự kiện'),
      );
      expect(notifier.state.items, isEmpty);
    });
  });
}

class _FakeEventsRepository implements EventsRepository {
  _FakeEventsRepository({this.error});

  final AppError? error;

  @override
  Future<EventListPageResult> getEvents({required EventListFilter filter}) async {
    final currentError = error;
    if (currentError != null) {
      throw currentError;
    }

    return EventListPageResult(
      items: <EventListItem>[
        EventListItem(
          eventId: 11,
          eventName: 'Sự kiện A',
          description: null,
          startTime: DateTime(2026, 3, 20, 8),
          endTime: DateTime(2026, 3, 20, 10),
          locationName: 'Hội trường A',
          maxParticipants: 100,
          currentParticipants: 50,
          status: 1,
          statusName: 'Mở đăng ký',
          eventTypeName: 'Workshop',
          instituteName: 'CNTT',
          registrationDeadline: DateTime(2026, 3, 18, 23, 59),
          thumbnailUrl: 'https://example.com/a.jpg',
          hasAvailableSlots: true,
        ),
        EventListItem(
          eventId: 10,
          eventName: 'Sự kiện B',
          description: null,
          startTime: DateTime(2026, 3, 18, 14),
          endTime: DateTime(2026, 3, 18, 16),
          locationName: 'Phòng B',
          maxParticipants: 80,
          currentParticipants: 80,
          status: 3,
          statusName: 'Đã kết thúc',
          eventTypeName: 'Talkshow',
          instituteName: 'QTKD',
          registrationDeadline: DateTime(2026, 3, 17, 18),
          thumbnailUrl: null,
          hasAvailableSlots: false,
        ),
      ],
      totalCount: 2,
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }
}
