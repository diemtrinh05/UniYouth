import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/domain/usecases/notifications/get_notifications_usecase.dart';
import 'package:uniyouth_app/domain/usecases/notifications/get_unread_count_usecase.dart';
import 'package:uniyouth_app/domain/usecases/notifications/mark_all_as_read_usecase.dart';
import 'package:uniyouth_app/domain/usecases/notifications/mark_as_read_usecase.dart';
import 'package:uniyouth_app/presentation/features/notifications/state/notification_notifier.dart';
import 'package:uniyouth_app/presentation/features/notifications/state/notification_state.dart';

void main() {
  group('NotificationNotifier', () {
    test('syncInitial updates list, unread count, and dedupes by id', () async {
      final repository = _FakeNotificationRepository()
        ..onGetNotifications = ({required filter}) async {
          return NotificationListPageResult(
            notifications: <NotificationListItem>[
              _notificationItem(id: 1, isRead: false),
              _notificationItem(id: 1, isRead: false),
            ],
            totalCount: 2,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        }
        ..onGetUnreadCount = () async => 5;

      int? syncedUnreadCount;
      final notifier = NotificationNotifier(
        getNotificationsUseCase: GetNotificationsUseCase(
          repository: repository,
        ),
        getUnreadCountUseCase: GetUnreadCountUseCase(repository: repository),
        markAsReadUseCase: MarkAsReadUseCase(repository: repository),
        markAllAsReadUseCase: MarkAllAsReadUseCase(repository: repository),
        onUnreadCountChanged: (value) {
          syncedUnreadCount = value;
        },
      );

      await notifier.syncInitial();

      expect(repository.getNotificationsCallCount, 1);
      expect(notifier.state.isInitialLoading, isFalse);
      expect(notifier.state.syncStatus, NotificationSyncStatus.synced);
      expect(notifier.state.unreadCount, 5);
      expect(notifier.state.items.length, 1);
      expect(syncedUnreadCount, 5);
    });

    test('loadMore does nothing when current state has no next page', () async {
      final repository = _FakeNotificationRepository()
        ..onGetNotifications = ({required filter}) async {
          return NotificationListPageResult(
            notifications: <NotificationListItem>[_notificationItem(id: 1)],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        }
        ..onGetUnreadCount = () async => 1;

      final notifier = NotificationNotifier(
        getNotificationsUseCase: GetNotificationsUseCase(
          repository: repository,
        ),
        getUnreadCountUseCase: GetUnreadCountUseCase(repository: repository),
        markAsReadUseCase: MarkAsReadUseCase(repository: repository),
        markAllAsReadUseCase: MarkAllAsReadUseCase(repository: repository),
      );

      await notifier.syncInitial();
      await notifier.loadMore();

      expect(repository.getNotificationsCallCount, 1);
      expect(notifier.state.items.length, 1);
    });

    test(
      'markAsRead updates item read-state and reloads unread count',
      () async {
        final unreadQueue = <int>[2, 1];
        final repository = _FakeNotificationRepository()
          ..onGetNotifications = ({required filter}) async {
            return NotificationListPageResult(
              notifications: <NotificationListItem>[
                _notificationItem(id: 1, isRead: false),
              ],
              totalCount: 1,
              pageNumber: 1,
              pageSize: filter.pageSize,
              totalPages: 1,
              hasPreviousPage: false,
              hasNextPage: false,
            );
          }
          ..onGetUnreadCount = () async => unreadQueue.removeAt(0);

        final notifier = NotificationNotifier(
          getNotificationsUseCase: GetNotificationsUseCase(
            repository: repository,
          ),
          getUnreadCountUseCase: GetUnreadCountUseCase(repository: repository),
          markAsReadUseCase: MarkAsReadUseCase(repository: repository),
          markAllAsReadUseCase: MarkAllAsReadUseCase(repository: repository),
        );

        await notifier.syncInitial();
        await notifier.markAsRead(item: notifier.state.items.first);

        expect(repository.markAsReadIds, <int>[1]);
        expect(notifier.state.items.first.isRead, isTrue);
        expect(notifier.state.unreadCount, 1);
      },
    );

    test('markAllAsRead marks all and refreshes list', () async {
      var listCall = 0;
      final repository = _FakeNotificationRepository()
        ..onGetNotifications = ({required filter}) async {
          listCall += 1;
          final isAfterMarkAll = listCall > 1;
          return NotificationListPageResult(
            notifications: <NotificationListItem>[
              _notificationItem(id: 1, isRead: isAfterMarkAll),
            ],
            totalCount: 1,
            pageNumber: 1,
            pageSize: filter.pageSize,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false,
          );
        }
        ..onGetUnreadCount = () async => 0;

      final notifier = NotificationNotifier(
        getNotificationsUseCase: GetNotificationsUseCase(
          repository: repository,
        ),
        getUnreadCountUseCase: GetUnreadCountUseCase(repository: repository),
        markAsReadUseCase: MarkAsReadUseCase(repository: repository),
        markAllAsReadUseCase: MarkAllAsReadUseCase(repository: repository),
      );

      await notifier.syncInitial();
      await notifier.markAllAsRead();

      expect(repository.markAllAsReadCallCount, 1);
      expect(repository.getNotificationsCallCount, greaterThanOrEqualTo(2));
      expect(notifier.state.items.first.isRead, isTrue);
    });

    test(
      'syncInitial sets failed status and error message when request fails',
      () async {
        final repository = _FakeNotificationRepository()
          ..onGetNotifications = ({required filter}) async {
            throw const AppError(
              type: AppErrorType.network,
              message: 'Network error.',
            );
          };

        final notifier = NotificationNotifier(
          getNotificationsUseCase: GetNotificationsUseCase(
            repository: repository,
          ),
          getUnreadCountUseCase: GetUnreadCountUseCase(repository: repository),
          markAsReadUseCase: MarkAsReadUseCase(repository: repository),
          markAllAsReadUseCase: MarkAllAsReadUseCase(repository: repository),
        );

        await notifier.syncInitial();

        expect(notifier.state.syncStatus, NotificationSyncStatus.failed);
        expect(notifier.state.errorMessage, isNotNull);
        expect(notifier.state.isInitialLoading, isFalse);
      },
    );
  });
}

class _FakeNotificationRepository implements NotificationRepository {
  int getNotificationsCallCount = 0;
  final List<int> markAsReadIds = <int>[];
  int markAllAsReadCallCount = 0;

  Future<NotificationListPageResult> Function({
    required NotificationListFilter filter,
  })?
  onGetNotifications;
  Future<int> Function()? onGetUnreadCount;
  Future<void> Function({required int notificationId})? onMarkAsRead;
  Future<void> Function()? onMarkAllAsRead;

  @override
  Future<NotificationListPageResult> getNotifications({
    required NotificationListFilter filter,
  }) async {
    getNotificationsCallCount += 1;
    final override = onGetNotifications;
    if (override != null) {
      return override(filter: filter);
    }
    return NotificationListPageResult(
      notifications: const <NotificationListItem>[],
      totalCount: 0,
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
      totalPages: 1,
      hasPreviousPage: false,
      hasNextPage: false,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final override = onGetUnreadCount;
    if (override != null) {
      return override();
    }
    return 0;
  }

  @override
  Future<void> markAsRead({required int notificationId}) async {
    markAsReadIds.add(notificationId);
    final override = onMarkAsRead;
    if (override != null) {
      await override(notificationId: notificationId);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    markAllAsReadCallCount += 1;
    final override = onMarkAllAsRead;
    if (override != null) {
      await override();
    }
  }
}

NotificationListItem _notificationItem({required int id, bool isRead = false}) {
  return NotificationListItem(
    notificationId: id,
    title: 'Title $id',
    content: 'Content $id',
    notificationType: 'general',
    priority: 1,
    isRead: isRead,
    readDate: isRead ? DateTime(2026, 1, 1) : null,
    actionUrl: null,
    eventId: null,
    eventName: null,
    createdDate: DateTime(2026, 1, id),
    expiryDate: null,
  );
}
