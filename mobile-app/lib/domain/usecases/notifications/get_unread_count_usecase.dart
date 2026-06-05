import '../../repositories/notifications/notification_repository.dart';

class GetUnreadCountUseCase {
  const GetUnreadCountUseCase({required NotificationRepository repository})
    : _repository = repository;

  final NotificationRepository _repository;

  // Read unread badge value from backend unread-count endpoint.
  Future<int> call() {
    return _repository.getUnreadCount();
  }
}
