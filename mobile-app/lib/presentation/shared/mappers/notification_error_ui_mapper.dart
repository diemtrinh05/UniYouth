import '../../../core/error/app_error.dart';
import '../../../core/error/app_error_type.dart';
import '../../../core/error/error_presenter.dart';

enum NotificationErrorOperation {
  loadNotifications,
  refreshNotifications,
  loadMoreNotifications,
  syncUnreadCount,
  markAsRead,
  markAllAsRead,
  syncDeviceToken,
  requestNotificationPermission,
}

class NotificationErrorUiMapper {
  const NotificationErrorUiMapper._();

  static String permissionDeniedGuidanceMessage() {
    return 'Bạn đã từ chối quyền thông báo. '
        'Vui lòng mở Cài đặt và cho phép quyền thông báo để không bỏ lỡ cập nhật quan trọng.';
  }

  static String openSettingsLabel() => 'Mở Cài đặt';

  static String remindLaterLabel() => 'Để sau';

  static String message(
    Object error, {
    required NotificationErrorOperation operation,
  }) {
    final operationLabel = _operationLabel(operation);

    if (error is AppError) {
      final backendMessage = _pickBackendMessage(error);
      if (backendMessage != null) {
        return 'Không thể $operationLabel. $backendMessage';
      }

      if (error.type == AppErrorType.network) {
        return 'Không thể $operationLabel. '
            'Không thể kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
      }

      if (error.statusCode == 401) {
        return 'Không thể $operationLabel. '
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      }

      if (error.statusCode == 403) {
        return 'Không thể $operationLabel. '
            'Bạn không có quyền thực hiện thao tác này.';
      }

      final presented = ErrorPresenter.presentStatusCode(error.statusCode);
      return 'Không thể $operationLabel. ${presented.message}';
    }

    if (error is FormatException) {
      return 'Không thể $operationLabel. ${error.message}';
    }

    return 'Không thể $operationLabel. '
        'Không thể xử lý yêu cầu lúc này. Vui lòng thử lại.';
  }

  static String _operationLabel(NotificationErrorOperation operation) {
    switch (operation) {
      case NotificationErrorOperation.loadNotifications:
        return 'tải thông báo';
      case NotificationErrorOperation.refreshNotifications:
        return 'làm mới thông báo';
      case NotificationErrorOperation.loadMoreNotifications:
        return 'tải thêm thông báo';
      case NotificationErrorOperation.syncUnreadCount:
        return 'đồng bộ số thông báo chưa đọc';
      case NotificationErrorOperation.markAsRead:
        return 'đánh dấu thông báo đã đọc';
      case NotificationErrorOperation.markAllAsRead:
        return 'đánh dấu tất cả thông báo đã đọc';
      case NotificationErrorOperation.syncDeviceToken:
        return 'đồng bộ token thiết bị';
      case NotificationErrorOperation.requestNotificationPermission:
        return 'xin quyền thông báo';
    }
  }

  static String? _pickBackendMessage(AppError error) {
    final message = error.message.trim();
    if (message.isEmpty) {
      return null;
    }

    if (_defaultParserMessages.contains(message)) {
      return null;
    }

    if (error.statusCode != null) {
      return message;
    }

    return null;
  }

  static const Set<String> _defaultParserMessages = <String>{
    'Request failed.',
    'Request timeout.',
    'Connection error.',
    'Request cancelled.',
    'Network error.',
  };
}
