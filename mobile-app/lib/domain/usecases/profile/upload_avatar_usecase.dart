class UploadAvatarFile {
  const UploadAvatarFile({required this.fileName, required this.bytes});

  final String fileName;
  final List<int> bytes;
}

class UploadAvatarResult {
  const UploadAvatarResult({required this.avatarUrl, required this.message});

  final String? avatarUrl;
  final String? message;
}

abstract class UploadAvatarRepository {
  Future<UploadAvatarResult> uploadAvatar({required UploadAvatarFile file});
}

class UploadAvatarUseCase {
  const UploadAvatarUseCase({required UploadAvatarRepository repository})
    : _repository = repository;

  final UploadAvatarRepository _repository;

  // Upload avatar binary as multipart field `file`.
  Future<UploadAvatarResult> call({required UploadAvatarFile file}) {
    return _repository.uploadAvatar(file: file);
  }
}
