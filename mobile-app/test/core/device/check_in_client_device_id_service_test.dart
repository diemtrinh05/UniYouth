import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/device/check_in_client_device_id_service.dart';
import 'package:uniyouth_app/core/storage/secure_key_value_storage.dart';

void main() {
  group('SecureCheckInClientDeviceIdService', () {
    test('reuses stored clientDeviceId when present', () async {
      final storage = _FakeSecureKeyValueStorage(
        initialValues: <String, String>{
          'attendance_client_device_id':
              '8d5b8ec0-0d66-4ad7-b6f0-f95c90d5d010',
        },
      );
      final service = SecureCheckInClientDeviceIdService(storage: storage);

      final result = await service.getClientDeviceId();

      expect(result, '8d5b8ec0-0d66-4ad7-b6f0-f95c90d5d010');
      expect(storage.writeCallCount, 0);
    });

    test('generates and persists uuid when storage is empty', () async {
      final storage = _FakeSecureKeyValueStorage();
      final service = SecureCheckInClientDeviceIdService(storage: storage);

      final first = await service.getClientDeviceId();
      final second = await service.getClientDeviceId();

      expect(first, isNotNull);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(first!),
        isTrue,
      );
      expect(second, first);
      expect(storage.writeCallCount, 1);
    });
  });
}

class _FakeSecureKeyValueStorage implements SecureKeyValueStorage {
  _FakeSecureKeyValueStorage({Map<String, String>? initialValues})
    : _values = <String, String>{...?initialValues};

  final Map<String, String> _values;
  int writeCallCount = 0;

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    writeCallCount += 1;
    _values[key] = value;
  }
}
