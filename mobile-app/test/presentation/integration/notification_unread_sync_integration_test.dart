import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/domain/usecases/notifications/get_notifications_usecase.dart';
import 'package:uniyouth_app/domain/usecases/notifications/get_unread_count_usecase.dart';
import 'package:uniyouth_app/domain/usecases/notifications/mark_all_as_read_usecase.dart';
import 'package:uniyouth_app/domain/usecases/notifications/mark_as_read_usecase.dart';
import 'package:uniyouth_app/presentation/app/providers/app_provider_graph.dart';
import 'package:uniyouth_app/presentation/features/notifications/state/notification_provider.dart';

void main() {
  test(
    'notification unread sync controller updates global unread provider from lifecycle stream',
    () async {
      final unreadRepository = _MutableUnreadNotificationRepository(
        unreadCount: 7,
      );
      final lifecycleController = StreamController<void>.broadcast();

      final container = ProviderContainer(
        overrides: [
          getNotificationsUseCaseProvider.overrideWithValue(
            GetNotificationsUseCase(repository: unreadRepository),
          ),
          getUnreadCountUseCaseProvider.overrideWithValue(
            GetUnreadCountUseCase(repository: unreadRepository),
          ),
          markAsReadUseCaseProvider.overrideWithValue(
            MarkAsReadUseCase(repository: unreadRepository),
          ),
          markAllAsReadUseCaseProvider.overrideWithValue(
            MarkAllAsReadUseCase(repository: unreadRepository),
          ),
          notificationLifecycleSyncStreamProvider.overrideWithValue(
            lifecycleController.stream,
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await lifecycleController.close();
      });

      final subscription = container.listen(
        notificationUnreadSyncControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container
          .read(notificationUnreadSyncControllerProvider)
          .syncUnreadCount();
      expect(container.read(notificationUnreadCountProvider), 7);

      unreadRepository.unreadCount = 3;
      lifecycleController.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(notificationUnreadCountProvider), 3);

      unreadRepository.shouldThrowOnUnread = true;
      lifecycleController.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(notificationUnreadCountProvider), 3);
    },
  );

  test(
    'notification notifier and global unread provider stay consistent after actions and lifecycle sync',
    () async {
      final repository = _MutableNotificationRepository(unreadCount: 2);
      final lifecycleController = StreamController<void>.broadcast();

      final container = ProviderContainer(
        overrides: [
          getNotificationsUseCaseProvider.overrideWithValue(
            GetNotificationsUseCase(repository: repository),
          ),
          getUnreadCountUseCaseProvider.overrideWithValue(
            GetUnreadCountUseCase(repository: repository),
          ),
          markAsReadUseCaseProvider.overrideWithValue(
            MarkAsReadUseCase(repository: repository),
          ),
          markAllAsReadUseCaseProvider.overrideWithValue(
            MarkAllAsReadUseCase(repository: repository),
          ),
          notificationLifecycleSyncStreamProvider.overrideWithValue(
            lifecycleController.stream,
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await lifecycleController.close();
      });

      final syncControllerSubscription = container.listen(
        notificationUnreadSyncControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(syncControllerSubscription.close);

      await container
          .read(notificationUnreadSyncControllerProvider)
          .syncUnreadCount();
      final notifier = container.read(notificationNotifierProvider.notifier);
      await notifier.syncInitial();

      expect(container.read(notificationNotifierProvider).unreadCount, 2);
      expect(container.read(notificationUnreadCountProvider), 2);

      final firstUnreadItem = container
          .read(notificationNotifierProvider)
          .items
          .firstWhere((item) => !(item.isRead ?? false));
      await notifier.markAsRead(item: firstUnreadItem);

      expect(container.read(notificationNotifierProvider).unreadCount, 1);
      expect(container.read(notificationUnreadCountProvider), 1);

      repository.setUnreadCount(3);
      lifecycleController.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final stateAfterLifecycleSync = container.read(
        notificationNotifierProvider,
      );
      expect(stateAfterLifecycleSync.unreadCount, 3);
      expect(container.read(notificationUnreadCountProvider), 3);
    },
  );
}

class _MutableUnreadNotificationRepository implements NotificationRepository {
  _MutableUnreadNotificationRepository({required this.unreadCount});

  int unreadCount;
  bool shouldThrowOnUnread = false;

  @override
  Future<NotificationListPageResult> getNotifications({
    required NotificationListFilter filter,
  }) {
    throw UnimplementedError('Not used in this integration test.');
  }

  @override
  Future<int> getUnreadCount() async {
    if (shouldThrowOnUnread) {
      throw Exception('unread-count failure');
    }
    return unreadCount;
  }

  @override
  Future<void> markAllAsRead() {
    throw UnimplementedError('Not used in this integration test.');
  }

  @override
  Future<void> markAsRead({required int notificationId}) {
    throw UnimplementedError('Not used in this integration test.');
  }
}

class _MutableNotificationRepository implements NotificationRepository {
  _MutableNotificationRepository({required int unreadCount})
    : _unreadCount = unreadCount {
    _items = _buildItems(unreadCount);
  }

  int _unreadCount;
  late List<NotificationListItem> _items;

  void setUnreadCount(int unreadCount) {
    _unreadCount = unreadCount;
    _items = _buildItems(unreadCount);
  }

  @override
  Future<NotificationListPageResult> getNotifications({
    required NotificationListFilter filter,
  }) async {
    return NotificationListPageResult(
      notifications: _items,
      totalCount: _items.length,
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    return _unreadCount;
  }

  @override
  Future<void> markAllAsRead() async {
    _unreadCount = 0;
    _items = _items
        .map(
          (item) => NotificationListItem(
            notificationId: item.notificationId,
            title: item.title,
            content: item.content,
            notificationType: item.notificationType,
            priority: item.priority,
            isRead: true,
            readDate: item.readDate,
            actionUrl: item.actionUrl,
            eventId: item.eventId,
            eventName: item.eventName,
            createdDate: item.createdDate,
            expiryDate: item.expiryDate,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> markAsRead({required int notificationId}) async {
    var decremented = false;
    _items = _items
        .map((item) {
          if (item.notificationId != notificationId || (item.isRead ?? false)) {
            return item;
          }
          decremented = true;
          return NotificationListItem(
            notificationId: item.notificationId,
            title: item.title,
            content: item.content,
            notificationType: item.notificationType,
            priority: item.priority,
            isRead: true,
            readDate: item.readDate,
            actionUrl: item.actionUrl,
            eventId: item.eventId,
            eventName: item.eventName,
            createdDate: item.createdDate,
            expiryDate: item.expiryDate,
          );
        })
        .toList(growable: false);
    if (decremented && _unreadCount > 0) {
      _unreadCount -= 1;
    }
  }

  static List<NotificationListItem> _buildItems(int unreadCount) {
    final normalizedUnreadCount = unreadCount < 0 ? 0 : unreadCount;
    final unreadItems = List<NotificationListItem>.generate(
      normalizedUnreadCount,
      (index) => _item(id: index + 1, isRead: false),
      growable: false,
    );
    return List<NotificationListItem>.unmodifiable(unreadItems);
  }
}

NotificationListItem _item({required int id, required bool isRead}) {
  return NotificationListItem(
    notificationId: id,
    title: 'N$id',
    content: 'Content $id',
    notificationType: 'general',
    priority: 1,
    isRead: isRead,
    readDate: null,
    actionUrl: null,
    eventId: null,
    eventName: null,
    createdDate: DateTime(2026, 1, 1, 8, id),
    expiryDate: null,
  );
}
