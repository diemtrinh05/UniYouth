import 'dart:math';

import '../storage/secure_key_value_storage.dart';

abstract class CheckInClientDeviceIdService {
  Future<String?> getClientDeviceId();
}

class SecureCheckInClientDeviceIdService
    implements CheckInClientDeviceIdService {
  SecureCheckInClientDeviceIdService({
    required SecureKeyValueStorage storage,
    Random? random,
  }) : _storage = storage,
       _random = random ?? Random.secure();

  static const String _storageKey = 'attendance_client_device_id';
  static const int _maxLength = 128;

  final SecureKeyValueStorage _storage;
  final Random _random;

  @override
  Future<String?> getClientDeviceId() async {
    try {
      final existing = (await _storage.read(key: _storageKey))?.trim();
      if (existing != null && existing.isNotEmpty) {
        return existing.length > _maxLength
            ? existing.substring(0, _maxLength)
            : existing;
      }

      final generated = _generateUuidV4();
      await _storage.write(key: _storageKey, value: generated);
      return generated;
    } catch (_) {
      return null;
    }
  }

  String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final uuid =
        '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
    return uuid.length > _maxLength ? uuid.substring(0, _maxLength) : uuid;
  }
}
