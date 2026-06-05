import 'app_error_type.dart';

AppErrorType mapStatusCodeToErrorType(int? statusCode) {
  switch (statusCode) {
    case 400:
      return AppErrorType.badRequest;
    case 401:
      return AppErrorType.unauthorized;
    case 403:
      return AppErrorType.forbidden;
    case 404:
      return AppErrorType.notFound;
    case 409:
      return AppErrorType.conflict;
    case 429:
      return AppErrorType.tooManyRequests;
    case 500:
      return AppErrorType.internalServerError;
    default:
      return AppErrorType.unknown;
  }
}
