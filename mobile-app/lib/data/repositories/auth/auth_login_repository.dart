import '../../../core/error/app_error.dart';
import '../../../core/error/app_error_type.dart';
import '../../../core/network/auth_token_provider.dart';
import '../../../domain/entities/auth/auth_session.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../datasources/remote/auth_remote_datasource.dart';
import 'auth_session_repository.dart';

class AuthLoginRepository implements LoginRepository {
  AuthLoginRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required AuthSessionRepository authSessionRepository,
    required InMemoryAuthTokenProvider tokenProvider,
  })  : _authRemoteDataSource = authRemoteDataSource,
        _authSessionRepository = authSessionRepository,
        _tokenProvider = tokenProvider;

  final AuthRemoteDataSource _authRemoteDataSource;
  final AuthSessionRepository _authSessionRepository;
  final InMemoryAuthTokenProvider _tokenProvider;

  @override
  Future<void> login({
    required String code,
    required String password,
  }) async {
    try {
      final loginResponse = await _authRemoteDataSource.login(
        code: code,
        password: password,
      );

      final session = AuthSession(
        token: loginResponse.token,
        expiresAt: loginResponse.expiresAt,
        refreshToken: loginResponse.refreshToken,
        refreshTokenExpiresAt: loginResponse.refreshTokenExpiresAt,
      );

      await _authSessionRepository.saveSession(session);
      _tokenProvider.setAccessToken(session.token);
    } on FormatException catch (error) {
      throw AppError(
        type: AppErrorType.unknown,
        message: error.message,
      );
    }
  }
}

