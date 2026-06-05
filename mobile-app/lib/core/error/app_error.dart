import 'app_error_type.dart';

class AppError implements Exception {
  const AppError({
    required this.type,
    required this.message,
    this.statusCode,
    this.fieldErrors,
    this.backendType,
    this.title,
    this.detail,
    this.isBackendMessage = false,
  });

  final AppErrorType type;
  final int? statusCode;
  final String message;
  final Map<String, List<String>>? fieldErrors;
  final String? backendType;
  final String? title;
  final String? detail;
  final bool isBackendMessage;

  @override
  String toString() {
    return 'AppError(type: $type, statusCode: $statusCode, message: $message)';
  }
}
