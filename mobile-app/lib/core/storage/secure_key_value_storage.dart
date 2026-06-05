import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureKeyValueStorage {
  Future<void> write({
    required String key,
    required String value,
  });

  Future<String?> read({
    required String key,
  });

  Future<void> delete({
    required String key,
  });
}

class FlutterSecureKeyValueStorage implements SecureKeyValueStorage {
  FlutterSecureKeyValueStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iOSOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  @override
  Future<void> write({
    required String key,
    required String value,
  }) {
    return _storage.write(
      key: key,
      value: value,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  @override
  Future<String?> read({
    required String key,
  }) {
    return _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }

  @override
  Future<void> delete({
    required String key,
  }) {
    return _storage.delete(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iOSOptions,
    );
  }
}
