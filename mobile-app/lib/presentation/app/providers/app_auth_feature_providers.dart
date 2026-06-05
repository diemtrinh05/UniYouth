import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth/auth_bootstrap_repository.dart';
import '../../../data/repositories/auth/auth_bootstrap_repository_impl.dart';
import '../../../data/repositories/auth/auth_health_repository.dart';
import '../../../data/repositories/auth/auth_login_repository.dart';
import '../../../data/repositories/auth/auth_password_recovery_repository.dart';
import '../../../domain/usecases/auth/bootstrap_auth_usecase.dart';
import '../../../domain/usecases/auth/check_api_health_usecase.dart';
import '../../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../../domain/usecases/auth/has_local_session_usecase.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/reset_password_usecase.dart';
import '../../../domain/usecases/auth/verify_reset_otp_usecase.dart';
import 'app_foundation_providers.dart';

final authBootstrapRepositoryProvider = Provider<AuthBootstrapRepository>(
  (ref) => AuthBootstrapRepositoryImpl(
    authSessionRepository: ref.watch(authSessionRepositoryProvider),
    usersRemoteDataSource: ref.watch(usersRemoteDataSourceProvider),
    tokenProvider: ref.watch(authTokenProvider),
  ),
);

class _AuthBootstrapUseCaseRepositoryAdapter
    implements BootstrapAuthRepository, HasLocalSessionRepository {
  const _AuthBootstrapUseCaseRepositoryAdapter({
    required AuthBootstrapRepository repository,
  }) : _repository = repository;

  final AuthBootstrapRepository _repository;

  @override
  Future<AuthBootstrapResult> bootstrap() async {
    final status = await _repository.bootstrap();
    if (status == AuthBootstrapStatus.authenticated) {
      return AuthBootstrapResult.authenticated;
    }
    return AuthBootstrapResult.unauthenticated;
  }

  @override
  Future<bool> hasLocalSession() {
    return _repository.hasLocalSession();
  }
}

final authLoginRepositoryProvider = Provider<AuthLoginRepository>(
  (ref) => AuthLoginRepository(
    authRemoteDataSource: ref.watch(authRemoteDataSourceProvider),
    authSessionRepository: ref.watch(authSessionRepositoryProvider),
    tokenProvider: ref.watch(authTokenProvider),
  ),
);

final authHealthRepositoryProvider = Provider<AuthHealthRepository>(
  (ref) => AuthHealthRepository(
    authRemoteDataSource: ref.watch(authRemoteDataSourceProvider),
  ),
);

final authPasswordRecoveryRepositoryProvider =
    Provider<AuthPasswordRecoveryRepository>(
      (ref) => AuthPasswordRecoveryRepository(
        authRemoteDataSource: ref.watch(authRemoteDataSourceProvider),
      ),
    );

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(repository: ref.watch(authLoginRepositoryProvider)),
);

final bootstrapAuthUseCaseProvider = Provider<BootstrapAuthUseCase>(
  (ref) => BootstrapAuthUseCase(
    repository: _AuthBootstrapUseCaseRepositoryAdapter(
      repository: ref.watch(authBootstrapRepositoryProvider),
    ),
  ),
);

final hasLocalSessionUseCaseProvider = Provider<HasLocalSessionUseCase>(
  (ref) => HasLocalSessionUseCase(
    repository: _AuthBootstrapUseCaseRepositoryAdapter(
      repository: ref.watch(authBootstrapRepositoryProvider),
    ),
  ),
);

final checkApiHealthUseCaseProvider = Provider<CheckApiHealthUseCase>(
  (ref) => CheckApiHealthUseCase(
    repository: ref.watch(authHealthRepositoryProvider),
  ),
);

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>(
  (ref) => ForgotPasswordUseCase(
    repository: ref.watch(authPasswordRecoveryRepositoryProvider),
  ),
);

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>(
  (ref) => ResetPasswordUseCase(
    repository: ref.watch(authPasswordRecoveryRepositoryProvider),
  ),
);

final verifyResetOtpUseCaseProvider = Provider<VerifyResetOtpUseCase>(
  (ref) => VerifyResetOtpUseCase(
    repository: ref.watch(authPasswordRecoveryRepositoryProvider),
  ),
);

class AuthNavigationBindings {
  const AuthNavigationBindings({
    required this.bootstrapAuthUseCase,
    required this.hasLocalSessionUseCase,
    required this.checkApiHealthUseCase,
    required this.loginUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
  });

  final BootstrapAuthUseCase Function() bootstrapAuthUseCase;
  final HasLocalSessionUseCase Function() hasLocalSessionUseCase;
  final CheckApiHealthUseCase Function() checkApiHealthUseCase;
  final LoginUseCase Function() loginUseCase;
  final ForgotPasswordUseCase Function() forgotPasswordUseCase;
  final ResetPasswordUseCase Function() resetPasswordUseCase;
}

final authNavigationBindingsProvider = Provider<AuthNavigationBindings>((ref) {
  final read = ref.read;
  return AuthNavigationBindings(
    bootstrapAuthUseCase: () => read(bootstrapAuthUseCaseProvider),
    hasLocalSessionUseCase: () => read(hasLocalSessionUseCaseProvider),
    checkApiHealthUseCase: () => read(checkApiHealthUseCaseProvider),
    loginUseCase: () => read(loginUseCaseProvider),
    forgotPasswordUseCase: () => read(forgotPasswordUseCaseProvider),
    resetPasswordUseCase: () => read(resetPasswordUseCaseProvider),
  );
});
