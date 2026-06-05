abstract class DeleteAvatarRepository {
  Future<void> deleteAvatar();
}

class DeleteAvatarUseCase {
  const DeleteAvatarUseCase({required DeleteAvatarRepository repository})
    : _repository = repository;

  final DeleteAvatarRepository _repository;

  // Delete current avatar for authenticated user.
  Future<void> call() {
    return _repository.deleteAvatar();
  }
}
