import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/data/models/attendance/attendance_history_item_model.dart';

void main() {
  group('AttendanceHistoryPageModel', () {
    test('parses attendance awarded-point flags from API response', () {
      final model = AttendanceHistoryPageModel.fromApiResponse({
        'data': {
          'items': [
            {
              'attendanceID': 101,
              'eventID': 202,
              'eventName': 'Sinh hoạt công dân',
              'checkInTime': '2026-04-06T08:30:00Z',
              'isValid': true,
              'distance': 10.8,
              'invalidReason': null,
              'hasAttendancePointsAwarded': false,
              'attendancePointID': null,
            },
          ],
          'totalCount': 1,
          'pageNumber': 1,
          'pageSize': 20,
          'totalPages': 1,
          'hasPreviousPage': false,
          'hasNextPage': false,
        },
      });

      expect(model.items, hasLength(1));
      final item = model.items.single;
      expect(item.attendanceId, 101);
      expect(item.hasAttendancePointsAwarded, isFalse);
      expect(item.attendancePointId, isNull);
    });
  });
}
