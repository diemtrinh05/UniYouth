abstract class LoginRepository {
  Future<void> login({
    required String code,
    required String password,
  });
}

class LoginUseCase {
  const LoginUseCase({
    required LoginRepository repository,
  }) : _repository = repository;

  final LoginRepository _repository;

  Future<void> call({
    required String code,
    required String password,
  }) {
    return _repository.login(
      code: code,
      password: password,
    );
  }
}

