import '../../../core/error/app_error.dart';
import '../../../core/error/error_presenter.dart';

class AppErrorUiMapper {
  const AppErrorUiMapper._();

  static String message(AppError error, {String? operation}) {
    return ErrorPresenter.presentAppError(error, operation: operation).message;
  }

  static String exceptionMessage({String? operation}) {
    return ErrorPresenter.presentException(operation: operation).message;
  }
}

