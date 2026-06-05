abstract class RegisterDeviceTokenRepository {
  Future<void> registerDeviceToken();
}

class RegisterDeviceTokenUseCase {
  const RegisterDeviceTokenUseCase({
    required RegisterDeviceTokenRepository repository,
  }) : _repository = repository;

  final RegisterDeviceTokenRepository _repository;

  Future<void> call() {
    return _repository.registerDeviceToken();
  }
}
