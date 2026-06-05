import '../../../domain/entities/notifications/notification_entity.dart';
import '../../../domain/entities/notifications/notification_priority.dart';
import '../../../domain/entities/notifications/notification_type.dart';
import '../../../domain/repositories/notifications/notification_repository.dart';
import '../../models/notifications/notification_item_model.dart';
import '../../datasources/remote/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationRepository {
  NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<NotificationListPageResult> getNotifications({
    required NotificationListFilter filter,
  }) async {
    final response = await _remoteDataSource.getNotifications(
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
    );

    final items = response.notifications
        .map(_mapToEntity)
        .map(_mapEntityToListItem)
        .toList(growable: false);

    return NotificationListPageResult(
      notifications: items,
      totalCount: response.totalCount,
      pageNumber: response.pageNumber,
      pageSize: response.pageSize,
      totalPages: response.totalPages,
      hasPreviousPage: response.hasPreviousPage,
      hasNextPage: response.hasNextPage,
    );
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  @override
  Future<void> markAsRead({required int notificationId}) {
    return _remoteDataSource.markAsRead(notificationId: notificationId);
  }

  @override
  Future<void> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }

  NotificationEntity _mapToEntity(NotificationItemModel model) {
    return NotificationEntity(
      notificationId: model.notificationId,
      title: model.title,
      content: model.content,
      notificationType: NotificationTypeParser.fromApiValue(
        model.notificationType,
      ),
      priority: NotificationPriorityParser.fromApiValue(model.priority),
      isRead: model.isRead,
      readDate: model.readDate,
      actionUrl: model.actionUrl,
      eventId: model.eventId,
      eventName: model.eventName,
      createdDate: model.createdDate,
      expiryDate: model.expiryDate,
    );
  }

  NotificationListItem _mapEntityToListItem(NotificationEntity entity) {
    return NotificationListItem(
      notificationId: entity.notificationId,
      title: entity.title,
      content: entity.content,
      notificationType: _mapNotificationTypeToRaw(entity.notificationType),
      priority: _mapPriorityToRaw(entity.priority),
      isRead: entity.isRead,
      readDate: entity.readDate,
      actionUrl: entity.actionUrl,
      eventId: entity.eventId,
      eventName: entity.eventName,
      createdDate: entity.createdDate,
      expiryDate: entity.expiryDate,
    );
  }

  String? _mapNotificationTypeToRaw(NotificationType type) {
    switch (type) {
      case NotificationType.eventRegistration:
        return 'EventRegistration';
      case NotificationType.attendance:
        return 'Attendance';
      case NotificationType.eventUpdate:
        return 'EventUpdate';
      case NotificationType.eventCancellation:
        return 'EventCancellation';
      case NotificationType.eventReminder:
        return 'EventReminder';
      case NotificationType.manualPoints:
        return 'ManualPoints';
      case NotificationType.system:
        return 'System';
      case NotificationType.unknown:
        return null;
    }
  }

  int? _mapPriorityToRaw(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.normal:
        return 0;
      case NotificationPriority.high:
        return 1;
      case NotificationPriority.critical:
        return 2;
      case NotificationPriority.unknown:
        return null;
    }
  }
}
