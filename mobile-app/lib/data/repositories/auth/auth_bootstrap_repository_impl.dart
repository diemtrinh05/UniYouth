import '../../../core/error/app_error.dart';
import '../../../core/error/app_error_type.dart';
import '../../../core/network/auth_token_provider.dart';
import '../../../domain/entities/auth/auth_session.dart';
import '../../datasources/remote/users_remote_datasource.dart';
import 'auth_bootstrap_repository.dart';
import 'auth_session_repository.dart';

class AuthBootstrapRepositoryImpl implements AuthBootstrapRepository {
  AuthBootstrapRepositoryImpl({
    required AuthSessionRepository authSessionRepository,
    required UsersRemoteDataSource usersRemoteDataSource,
    required InMemoryAuthTokenProvider tokenProvider,
  }) : _authSessionRepository = authSessionRepository,
       _usersRemoteDataSource = usersRemoteDataSource,
       _tokenProvider = tokenProvider;

  final AuthSessionRepository _authSessionRepository;
  final UsersRemoteDataSource _usersRemoteDataSource;
  final InMemoryAuthTokenProvider _tokenProvider;

  @override
  Future<AuthBootstrapStatus> bootstrap() async {
    final session = await _authSessionRepository.readSession();
    if (session == null) {
      _tokenProvider.setAccessToken(null);
      return AuthBootstrapStatus.unauthenticated;
    }

    _applySessionToTokenProvider(session);

    try {
      await _usersRemoteDataSource.getMyProfile();
      return AuthBootstrapStatus.authenticated;
    } on AppError catch (error) {
      if (error.type == AppErrorType.unauthorized) {
        await _authSessionRepository.clearSession();
        _tokenProvider.setAccessToken(null);
      }
      return AuthBootstrapStatus.unauthenticated;
    }
  }

  @override
  Future<bool> hasLocalSession() async {
    final inMemoryToken = await _tokenProvider.getAccessToken();
    if (inMemoryToken != null && inMemoryToken.trim().isNotEmpty) {
      return true;
    }

    final session = await _authSessionRepository.readSession();
    if (session == null) {
      _tokenProvider.setAccessToken(null);
      return false;
    }

    _applySessionToTokenProvider(session);
    return true;
  }

  void _applySessionToTokenProvider(AuthSession session) {
    _tokenProvider.setAccessToken(session.token);
  }
}
