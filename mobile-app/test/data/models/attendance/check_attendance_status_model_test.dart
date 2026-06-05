import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/data/models/attendance/check_attendance_status_model.dart';

void main() {
  group('CheckAttendanceStatusModel', () {
    test('fromApiResponse parses isValid and invalidReason from envelope', () {
      final model = CheckAttendanceStatusModel.fromApiResponse(
        <String, dynamic>{
          'data': <String, dynamic>{
            'eventId': 101,
            'hasCheckedIn': true,
            'isValid': false,
            'invalidReason': 'Khoảng cách quá xa so với bán kính cho phép.',
          },
        },
      );

      expect(model.eventId, 101);
      expect(model.hasCheckedIn, isTrue);
      expect(model.isValid, isFalse);
      expect(
        model.invalidReason,
        'Khoảng cách quá xa so với bán kính cho phép.',
      );
    });

    test('fromJson keeps nullable validity fields when backend omits them', () {
      final model = CheckAttendanceStatusModel.fromJson(
        <String, dynamic>{'eventId': 101, 'hasCheckedIn': false},
      );

      expect(model.eventId, 101);
      expect(model.hasCheckedIn, isFalse);
      expect(model.isValid, isNull);
      expect(model.invalidReason, isNull);
    });
  });
}
