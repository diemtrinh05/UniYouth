import 'notification_priority.dart';
import 'notification_type.dart';

class NotificationEntity {
  const NotificationEntity({
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
  final NotificationType notificationType;
  final NotificationPriority priority;
  final bool? isRead;
  final DateTime? readDate;
  final String? actionUrl;
  final int? eventId;
  final String? eventName;
  final DateTime? createdDate;
  final DateTime? expiryDate;
}

