import 'app_error.dart';

class PresentedError {
  const PresentedError({
    required this.title,
    required this.message,
    this.statusCode,
  });

  final String title;
  final String message;
  final int? statusCode;
}

class ErrorPresenter {
  const ErrorPresenter._();

  // Shared status-code to UX mapping for the whole app.
  static const Map<int, PresentedError> _statusMapping = <int, PresentedError>{
    400: PresentedError(
      statusCode: 400,
      title: 'Yêu cầu không hợp lệ',
      message: 'Dữ liệu gửi lên không hợp lệ. Vui lòng kiểm tra và thử lại.',
    ),
    401: PresentedError(
      statusCode: 401,
      title: 'Phiên đăng nhập hết hạn',
      message: 'Vui lòng đăng nhập lại để tiếp tục.',
    ),
    403: PresentedError(
      statusCode: 403,
      title: 'Không có quyền truy cập',
      message: 'Bạn không có quyền thực hiện thao tác này.',
    ),
    404: PresentedError(
      statusCode: 404,
      title: 'Không tìm thấy dữ liệu',
      message: 'Dữ liệu yêu cầu không tồn tại hoặc đã bị thay đổi.',
    ),
    409: PresentedError(
      statusCode: 409,
      title: 'Xung đột dữ liệu',
      message: 'Dữ liệu đang thay đổi. Vui lòng tải lại và thử lại.',
    ),
    429: PresentedError(
      statusCode: 429,
      title: 'Thao tác quá nhanh',
      message: 'Bạn thao tác quá nhanh. Vui lòng đợi ít giây rồi thử lại.',
    ),
    500: PresentedError(
      statusCode: 500,
      title: 'Lỗi hệ thống',
      message: 'Hệ thống tạm thời gặp sự cố. Vui lòng thử lại sau.',
    ),
  };

  static const PresentedError _fallbackError = PresentedError(
    title: 'Có lỗi xảy ra',
    message: 'Không thể xử lý yêu cầu lúc này. Vui lòng thử lại.',
  );

  static PresentedError presentAppError(AppError error, {String? operation}) {
    final mapped = presentStatusCode(error.statusCode);
    final backendMessage = _backendMessageOrNull(error);
    final resolvedMessage = backendMessage ?? mapped.message;

    if (operation == null || operation.trim().isEmpty) {
      return PresentedError(
        statusCode: mapped.statusCode,
        title: mapped.title,
        message: resolvedMessage,
      );
    }
    return PresentedError(
      statusCode: mapped.statusCode,
      title: mapped.title,
      message: 'Không thể $operation. $resolvedMessage',
    );
  }

  static PresentedError presentStatusCode(int? statusCode) {
    if (statusCode == null) {
      return _fallbackError;
    }
    if (statusCode >= 500) {
      return _statusMapping[500]!;
    }
    return _statusMapping[statusCode] ?? _fallbackError;
  }

  static PresentedError presentException({String? operation}) {
    if (operation == null || operation.trim().isEmpty) {
      return _fallbackError;
    }

    return PresentedError(
      title: _fallbackError.title,
      message: 'Không thể $operation. ${_fallbackError.message}',
    );
  }

  static String? _backendMessageOrNull(AppError error) {
    final message = error.message.trim();
    if (message.isEmpty) {
      return null;
    }

    if (error.isBackendMessage) {
      return message;
    }

    return null;
  }
}
