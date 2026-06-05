import 'package:file_picker/file_picker.dart';

import '../../../../../domain/usecases/profile/upload_avatar_usecase.dart';

abstract class AvatarPickerService {
  Future<UploadAvatarFile?> pickAvatarFile();
}

class FilePickerAvatarPickerService implements AvatarPickerService {
  @override
  Future<UploadAvatarFile?> pickAvatarFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    final fileName = file.name.trim();
    if (bytes == null || bytes.isEmpty || fileName.isEmpty) {
      return null;
    }

    return UploadAvatarFile(
      fileName: fileName,
      bytes: bytes.toList(growable: false),
    );
  }
}
