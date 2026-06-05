class NotificationListFilter {
  const NotificationListFilter({
    required this.pageNumber,
    required this.pageSize,
  });

  final int pageNumber;
  final int pageSize;
}

class NotificationListItem {
  const NotificationListItem({
    required this.notificationId,
    required this.title,
    required this.content,
    required this.notificationType,
    required this.priority,
    required this.isRead,
    required this.readDate,
    required this.actionUrl,
    required this.eventId,
    required this.eventName,
    required this.createdDate,
    required this.expiryDate,
  });

  final int notificationId;
  final String? title;
  final String? content;
  final String? notificationType;
  final int? priority;
  final bool? isRead;
  final DateTime? readDate;
  final String? actionUrl;
  final int? eventId;
  final String? eventName;
  final DateTime? createdDate;
  final DateTime? expiryDate;
}

class NotificationListPageResult {
  const NotificationListPageResult({
    required this.notifications,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<NotificationListItem> notifications;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
}

abstract class NotificationRepository {
  Future<NotificationListPageResult> getNotifications({
    required NotificationListFilter filter,
  });

  Future<int> getUnreadCount();

  Future<void> markAsRead({required int notificationId});

  Future<void> markAllAsRead();
}

