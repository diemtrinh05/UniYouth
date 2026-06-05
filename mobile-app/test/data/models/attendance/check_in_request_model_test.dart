import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/data/models/attendance/check_in_request_model.dart';

void main() {
  group('CheckInRequestModel', () {
    test('includes deviceInfo when provided', () {
      const model = CheckInRequestModel(
        qrToken: 'qr-token',
        latitude: 10.123456,
        longitude: 106.123456,
        deviceInfo: 'Android 14 | Pixel 8 | UniYouth 1.0.0',
        clientDeviceId: '8d5b8ec0-0d66-4ad7-b6f0-f95c90d5d010',
      );

      expect(model.toJson(), <String, dynamic>{
        'qrToken': 'qr-token',
        'latitude': 10.123456,
        'longitude': 106.123456,
        'deviceInfo': 'Android 14 | Pixel 8 | UniYouth 1.0.0',
        'clientDeviceId': '8d5b8ec0-0d66-4ad7-b6f0-f95c90d5d010',
      });
    });

    test('omits deviceInfo and clientDeviceId when null', () {
      const model = CheckInRequestModel(
        qrToken: 'qr-token',
        latitude: 10.123456,
        longitude: 106.123456,
      );

      expect(model.toJson().containsKey('deviceInfo'), isFalse);
      expect(model.toJson().containsKey('clientDeviceId'), isFalse);
    });
  });
}
