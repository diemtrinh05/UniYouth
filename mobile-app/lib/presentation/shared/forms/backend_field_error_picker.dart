import '../../../core/error/app_error.dart';

class BackendFieldErrorPicker {
  const BackendFieldErrorPicker._();

  static String? first(AppError error, List<String> candidateKeys) {
    final fieldErrors = error.fieldErrors;
    if (fieldErrors == null || fieldErrors.isEmpty) {
      return null;
    }

    final normalized = <String, String>{};
    for (final entry in fieldErrors.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      final message = entry.value.first.trim();
      if (message.isEmpty) {
        continue;
      }
      normalized[_normalizeKey(entry.key)] = message;
    }

    for (final key in candidateKeys) {
      final message = normalized[_normalizeKey(key)];
      if (message != null) {
        return message;
      }
    }

    return null;
  }

  static String _normalizeKey(String key) {
    final trimmed = key.trim();
    final withoutJsonPointer = trimmed.startsWith('\$.')
        ? trimmed.substring(2)
        : (trimmed.startsWith('.') ? trimmed.substring(1) : trimmed);
    return withoutJsonPointer.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
