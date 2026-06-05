import '../../../domain/entities/auth/auth_session.dart';

abstract class AuthSessionRepository {
  Future<void> saveSession(AuthSession session);

  Future<AuthSession?> readSession();

  Future<void> clearSession();
}
