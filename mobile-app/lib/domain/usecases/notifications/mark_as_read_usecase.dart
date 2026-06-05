import '../../repositories/notifications/notification_repository.dart';

class MarkAsReadUseCase {
  const MarkAsReadUseCase({required NotificationRepository repository})
    : _repository = repository;

  final NotificationRepository _repository;

  // Mark a single notification as read by id.
  Future<void> call({required int notificationId}) {
    return _repository.markAsRead(notificationId: notificationId);
  }
}
