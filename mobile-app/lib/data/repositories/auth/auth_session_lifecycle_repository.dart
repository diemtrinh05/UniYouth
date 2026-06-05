import '../../../core/error/app_error.dart';
import '../../../core/error/app_error_type.dart';
import '../../../core/network/auth_token_provider.dart';
import '../../../domain/entities/auth/auth_session.dart';
import '../../datasources/remote/auth_remote_datasource.dart';
import 'auth_session_repository.dart';

class AuthSessionLifecycleRepository {
  AuthSessionLifecycleRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required AuthSessionRepository authSessionRepository,
    required InMemoryAuthTokenProvider tokenProvider,
  }) : _authRemoteDataSource = authRemoteDataSource,
       _authSessionRepository = authSessionRepository,
       _tokenProvider = tokenProvider;

  final AuthRemoteDataSource _authRemoteDataSource;
  final AuthSessionRepository _authSessionRepository;
  final InMemoryAuthTokenProvider _tokenProvider;

  Future<bool> tryRefreshSession() async {
    final currentSession = await _authSessionRepository.readSession();
    final refreshToken = currentSession?.refreshToken?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final refreshExpiresAt = currentSession?.refreshTokenExpiresAt;
    if (refreshExpiresAt != null && refreshExpiresAt.isBefore(DateTime.now())) {
      await clearSession();
      return false;
    }

    try {
      final refreshed = await _authRemoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );

      final nextSession = AuthSession(
        token: refreshed.token,
        expiresAt: refreshed.expiresAt,
        refreshToken: refreshed.refreshToken ?? refreshToken,
        refreshTokenExpiresAt:
            refreshed.refreshTokenExpiresAt ?? refreshExpiresAt,
      );

      await _authSessionRepository.saveSession(nextSession);
      _tokenProvider.setAccessToken(nextSession.token);
      return true;
    } on AppError catch (error) {
      if (error.type == AppErrorType.unauthorized) {
        await clearSession();
        return false;
      }
      rethrow;
    } on FormatException {
      await clearSession();
      return false;
    }
  }

  Future<void> revokeCurrentSession() async {
    final currentSession = await _authSessionRepository.readSession();
    final refreshToken = currentSession?.refreshToken?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    try {
      await _authRemoteDataSource.revokeToken(refreshToken: refreshToken);
    } on AppError catch (_) {
      // Logout vẫn tiếp tục xóa session local dù revoke remote fail.
    }
  }

  Future<void> clearSession() async {
    await _authSessionRepository.clearSession();
    _tokenProvider.setAccessToken(null);
  }
}
