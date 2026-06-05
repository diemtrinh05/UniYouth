enum AuthBootstrapResult { authenticated, unauthenticated }

abstract class BootstrapAuthRepository {
  Future<AuthBootstrapResult> bootstrap();
}

class BootstrapAuthUseCase {
  const BootstrapAuthUseCase({required BootstrapAuthRepository repository})
    : _repository = repository;

  final BootstrapAuthRepository _repository;

  Future<AuthBootstrapResult> call() {
    return _repository.bootstrap();
  }
}
