import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/domain/usecases/points/get_points_history_usecase.dart';
import 'package:uniyouth_app/presentation/features/points/points_history/state/points_history_notifier.dart';

void main() {
  group('PointsHistoryNotifier', () {
    test('syncInitial loads first page with default page size', () async {
      final repository = _FakePointsHistoryRepository()
        ..onGetPointsHistory = ({required filter}) async {
          return PointsHistoryPageResult(
            items: <PointsHistoryItem>[
              _historyItem(id: 1, createdDate: DateTime(2026, 1, 1)),
            ],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        };
      final notifier = PointsHistoryNotifier(
        getPointsHistoryUseCase: GetPointsHistoryUseCase(
          repository: repository,
        ),
      );
      addTearDown(notifier.dispose);

      await notifier.syncInitial();

      expect(repository.filters.length, 1);
      expect(repository.filters.first.pageSize, 20);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.isInitialLoading, isFalse);
    });

    test('loadMore does nothing when hasNextPage is false', () async {
      final repository = _FakePointsHistoryRepository()
        ..onGetPointsHistory = ({required filter}) async {
          return PointsHistoryPageResult(
            items: <PointsHistoryItem>[_historyItem(id: 1)],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        };
      final notifier = PointsHistoryNotifier(
        getPointsHistoryUseCase: GetPointsHistoryUseCase(
          repository: repository,
        ),
      );
      addTearDown(notifier.dispose);

      await notifier.syncInitial();
      await notifier.loadMore();

      expect(repository.filters.length, 1);
      expect(notifier.state.items.length, 1);
    });
  });
}

class _FakePointsHistoryRepository implements GetPointsHistoryRepository {
  final List<PointsHistoryFilter> filters = <PointsHistoryFilter>[];

  Future<PointsHistoryPageResult> Function({
    required PointsHistoryFilter filter,
  })?
  onGetPointsHistory;

  @override
  Future<PointsHistoryPageResult> getPointsHistory({
    required PointsHistoryFilter filter,
  }) async {
    filters.add(filter);
    final override = onGetPointsHistory;
    if (override != null) {
      return override(filter: filter);
    }
    return PointsHistoryPageResult(
      items: const <PointsHistoryItem>[],
      totalCount: 0,
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }
}

PointsHistoryItem _historyItem({required int id, DateTime? createdDate}) {
  return PointsHistoryItem(
    pointId: id,
    eventId: 10,
    eventName: 'Event $id',
    eventStartTime: DateTime(2026, 1, 1, 8),
    points: 10,
    pointType: 'attendance',
    roleType: 'member',
    awardedByName: 'System',
    createdDate: createdDate ?? DateTime(2026, 1, 1, 9),
  );
}
