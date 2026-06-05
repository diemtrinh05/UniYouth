abstract class ForgotPasswordRepository {
  Future<String> forgotPassword({
    required String account,
  });
}

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase({
    required ForgotPasswordRepository repository,
  }) : _repository = repository;

  final ForgotPasswordRepository _repository;

  Future<String> call({
    required String account,
  }) {
    return _repository.forgotPassword(account: account);
  }
}
