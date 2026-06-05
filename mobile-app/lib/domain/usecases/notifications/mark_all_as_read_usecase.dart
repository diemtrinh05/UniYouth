import '../../repositories/notifications/notification_repository.dart';

class MarkAllAsReadUseCase {
  const MarkAllAsReadUseCase({required NotificationRepository repository})
    : _repository = repository;

  final NotificationRepository _repository;

  // Mark all notifications as read for current user.
  Future<void> call() {
    return _repository.markAllAsRead();
  }
}
