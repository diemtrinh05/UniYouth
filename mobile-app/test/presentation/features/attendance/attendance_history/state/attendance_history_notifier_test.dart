import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/domain/usecases/attendance/get_my_history_usecase.dart';
import 'package:uniyouth_app/presentation/features/attendance/attendance_history/state/attendance_history_notifier.dart';

void main() {
  group('AttendanceHistoryNotifier', () {
    test('syncInitial loads first page with default page size', () async {
      final repository = _FakeAttendanceHistoryRepository()
        ..onGetMyHistory = ({required filter}) async {
          return AttendanceHistoryPageResult(
            items: <AttendanceHistoryItem>[_historyItem(id: 1)],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        };
      final notifier = AttendanceHistoryNotifier(
        getMyHistoryUseCase: GetMyHistoryUseCase(repository: repository),
      );
      addTearDown(notifier.dispose);

      await notifier.syncInitial();

      expect(repository.filters.length, 1);
      expect(repository.filters.first.pageSize, 20);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.isInitialLoading, isFalse);
    });

    test('loadMore does nothing when hasNextPage is false', () async {
      final repository = _FakeAttendanceHistoryRepository()
        ..onGetMyHistory = ({required filter}) async {
          return AttendanceHistoryPageResult(
            items: <AttendanceHistoryItem>[_historyItem(id: 1)],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        };
      final notifier = AttendanceHistoryNotifier(
        getMyHistoryUseCase: GetMyHistoryUseCase(repository: repository),
      );
      addTearDown(notifier.dispose);

      await notifier.syncInitial();
      await notifier.loadMore();

      expect(repository.filters.length, 1);
      expect(notifier.state.items.length, 1);
    });
  });
}

class _FakeAttendanceHistoryRepository implements GetMyHistoryRepository {
  final List<AttendanceHistoryFilter> filters = <AttendanceHistoryFilter>[];

  Future<AttendanceHistoryPageResult> Function({
    required AttendanceHistoryFilter filter,
  })?
  onGetMyHistory;

  @override
  Future<AttendanceHistoryPageResult> getMyHistory({
    required AttendanceHistoryFilter filter,
  }) async {
    filters.add(filter);
    final override = onGetMyHistory;
    if (override != null) {
      return override(filter: filter);
    }
    return AttendanceHistoryPageResult(
      items: const <AttendanceHistoryItem>[],
      totalCount: 0,
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }
}

AttendanceHistoryItem _historyItem({required int id}) {
  return AttendanceHistoryItem(
    attendanceId: id,
    checkInTime: DateTime(2026, 1, 1, 8),
    checkInMethod: 'QR',
    isValid: true,
    invalidReason: null,
    distance: 2.0,
    eventName: 'Event $id',
    hasAttendancePointsAwarded: false,
    attendancePointId: null,
  );
}
