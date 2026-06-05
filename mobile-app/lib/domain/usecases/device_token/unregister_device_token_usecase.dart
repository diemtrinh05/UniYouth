abstract class UnregisterDeviceTokenRepository {
  Future<void> unregisterDeviceToken();
}

class UnregisterDeviceTokenUseCase {
  const UnregisterDeviceTokenUseCase({
    required UnregisterDeviceTokenRepository repository,
  }) : _repository = repository;

  final UnregisterDeviceTokenRepository _repository;

  Future<void> call() {
    return _repository.unregisterDeviceToken();
  }
}
