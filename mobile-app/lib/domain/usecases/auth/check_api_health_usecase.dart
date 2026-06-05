abstract class CheckApiHealthRepository {
  Future<bool> checkApiHealth();
}

class CheckApiHealthUseCase {
  const CheckApiHealthUseCase({
    required CheckApiHealthRepository repository,
  }) : _repository = repository;

  final CheckApiHealthRepository _repository;

  Future<bool> call() {
    return _repository.checkApiHealth();
  }
}
