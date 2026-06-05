import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/network/idempotency_key_provider.dart';
import 'package:uniyouth_app/data/datasources/remote/events_remote_datasource.dart';
import 'package:uniyouth_app/data/models/attendance/attendance_history_item_model.dart';
import 'package:uniyouth_app/data/repositories/events_repository_impl.dart';
import 'package:uniyouth_app/domain/usecases/attendance/get_my_history_usecase.dart';

void main() {
  group('EventsRepositoryImpl.getMyHistory', () {
    test('maps attendance point-award flags into domain model', () async {
      final repository = EventsRepositoryImpl(
        remoteDataSource: _FakeEventsRemoteDataSource(
          historyPageModel: AttendanceHistoryPageModel(
            items: const [
              AttendanceHistoryItemModel(
                attendanceId: 88,
                checkInTime: null,
                checkInMethod: 'QR_GPS',
                isValid: true,
                invalidReason: null,
                distance: 5.5,
                eventName: 'Ngày hội tình nguyện',
                hasAttendancePointsAwarded: false,
                attendancePointId: null,
              ),
            ],
            totalCount: 1,
            pageNumber: 1,
            pageSize: 20,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          ),
        ),
        idempotencyKeyProvider: const _FakeIdempotencyKeyProvider(),
      );

      final result = await repository.getMyHistory(
        filter: const AttendanceHistoryFilter(pageNumber: 1, pageSize: 20),
      );

      expect(result.items, hasLength(1));
      final item = result.items.single;
      expect(item.attendanceId, 88);
      expect(item.hasAttendancePointsAwarded, isFalse);
      expect(item.attendancePointId, isNull);
    });
  });
}

class _FakeEventsRemoteDataSource extends EventsRemoteDataSource {
  _FakeEventsRemoteDataSource({required this.historyPageModel})
    : super(dio: Dio());

  final AttendanceHistoryPageModel historyPageModel;

  @override
  Future<AttendanceHistoryPageModel> getMyAttendanceHistory({
    required int pageNumber,
    required int pageSize,
  }) async {
    return historyPageModel;
  }
}

class _FakeIdempotencyKeyProvider implements IdempotencyKeyProvider {
  const _FakeIdempotencyKeyProvider();

  @override
  String generateKey({required String scope}) => '$scope-test-key';
}
