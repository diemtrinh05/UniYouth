import '../../repositories/notifications/notification_repository.dart';

export '../../repositories/notifications/notification_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase({
    required NotificationRepository repository,
  }) : _repository = repository;

  final NotificationRepository _repository;

  // Load paginated notification list for current user.
  Future<NotificationListPageResult> call({
    required NotificationListFilter filter,
  }) {
    return _repository.getNotifications(filter: filter);
  }
}
