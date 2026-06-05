import '../../../core/storage/secure_key_value_storage.dart';
import '../../../domain/entities/auth/auth_session.dart';
import 'auth_session_repository.dart';

class SecureAuthSessionRepository implements AuthSessionRepository {
  SecureAuthSessionRepository({
    required SecureKeyValueStorage storage,
  }) : _storage = storage;

  final SecureKeyValueStorage _storage;

  static const _tokenKey = 'auth.token';
  static const _expiresAtKey = 'auth.expiresAt';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _refreshExpiresAtKey = 'auth.refreshExpiresAt';

  @override
  Future<void> saveSession(AuthSession session) async {
    await _storage.write(
      key: _tokenKey,
      value: session.token,
    );
    await _storage.write(
      key: _expiresAtKey,
      value: session.expiresAt.toIso8601String(),
    );
    if (session.refreshToken != null && session.refreshToken!.trim().isNotEmpty) {
      await _storage.write(
        key: _refreshTokenKey,
        value: session.refreshToken!,
      );
    } else {
      await _storage.delete(key: _refreshTokenKey);
    }

    if (session.refreshTokenExpiresAt != null) {
      await _storage.write(
        key: _refreshExpiresAtKey,
        value: session.refreshTokenExpiresAt!.toIso8601String(),
      );
    } else {
      await _storage.delete(key: _refreshExpiresAtKey);
    }
  }

  @override
  Future<AuthSession?> readSession() async {
    final token = await _storage.read(key: _tokenKey);
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final refreshExpiresAtRaw = await _storage.read(key: _refreshExpiresAtKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }
    if (expiresAtRaw == null || expiresAtRaw.trim().isEmpty) {
      return null;
    }

    final parsedExpiresAt = DateTime.tryParse(expiresAtRaw);
    final parsedRefreshExpiresAt = DateTime.tryParse(refreshExpiresAtRaw ?? '');
    if (parsedExpiresAt == null) {
      return null;
    }

    return AuthSession(
      token: token,
      expiresAt: parsedExpiresAt,
      refreshToken: refreshToken,
      refreshTokenExpiresAt: parsedRefreshExpiresAt,
    );
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _refreshExpiresAtKey);
  }
}
