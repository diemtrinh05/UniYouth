abstract class HasLocalSessionRepository {
  Future<bool> hasLocalSession();
}

class HasLocalSessionUseCase {
  const HasLocalSessionUseCase({required HasLocalSessionRepository repository})
    : _repository = repository;

  final HasLocalSessionRepository _repository;

  Future<bool> call() {
    return _repository.hasLocalSession();
  }
}
