import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/usecases/notifications/get_notifications_usecase.dart';
import '../../../../../domain/usecases/notifications/get_unread_count_usecase.dart';
import '../../../../../domain/usecases/notifications/mark_all_as_read_usecase.dart';
import '../../../../../domain/usecases/notifications/mark_as_read_usecase.dart';
import '../../../shared/mappers/notification_error_ui_mapper.dart';
import 'notification_state.dart';

typedef NotificationUnreadCountSync = void Function(int unreadCount);

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required MarkAllAsReadUseCase markAllAsReadUseCase,
    NotificationUnreadCountSync? onUnreadCountChanged,
    Stream<void>? lifecycleSyncStream,
    int defaultPageSize = 20,
  }) : _getNotificationsUseCase = getNotificationsUseCase,
       _getUnreadCountUseCase = getUnreadCountUseCase,
       _markAsReadUseCase = markAsReadUseCase,
       _markAllAsReadUseCase = markAllAsReadUseCase,
       _onUnreadCountChanged = onUnreadCountChanged ?? _noopUnreadCountSync,
       _defaultPageSize = defaultPageSize,
       super(const NotificationState()) {
    if (lifecycleSyncStream != null) {
      _lifecycleSyncSubscription = lifecycleSyncStream.listen((_) {
        _scheduleLifecycleRefresh();
      });
    }
  }

  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final MarkAllAsReadUseCase _markAllAsReadUseCase;
  final NotificationUnreadCountSync _onUnreadCountChanged;
  final int _defaultPageSize;

  StreamSubscription<void>? _lifecycleSyncSubscription;
  bool _isLifecycleRefreshRunning = false;
  bool _hasPendingLifecycleRefresh = false;
  Future<int>? _inFlightUnreadRequest;
  bool _isDisposed = false;

  List<NotificationListItem> get filteredItems {
    switch (state.readFilter) {
      case NotificationReadFilter.all:
        return state.items;
      case NotificationReadFilter.unread:
        return state.items
            .where((item) => !(item.isRead ?? false))
            .toList(growable: false);
      case NotificationReadFilter.read:
        return state.items
            .where((item) => item.isRead ?? false)
            .toList(growable: false);
    }
  }

  Future<void> syncInitial() async {
    _setState(
      state.copyWith(
        isInitialLoading: true,
        isRefreshing: false,
        isPassiveSyncing: false,
        syncStatus: NotificationSyncStatus.syncing,
        clearInfoMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final results = await Future.wait<Object>([
        _getNotificationsUseCase(
          filter: NotificationListFilter(
            pageNumber: 1,
            pageSize: _defaultPageSize,
          ),
        ),
        _requestUnreadCount(),
      ]);

      final listResult = results[0] as NotificationListPageResult;
      final unreadCount = results[1] as int;
      final dedupedItems = _dedupeById(listResult.notifications);

      _setState(
        state.copyWith(
          items: List<NotificationListItem>.unmodifiable(dedupedItems),
          unreadCount: unreadCount,
          totalCount: listResult.totalCount,
          pageNumber: listResult.pageNumber,
          pageSize: listResult.pageSize,
          totalPages: listResult.totalPages,
          hasPreviousPage: listResult.hasPreviousPage,
          hasNextPage: listResult.hasNextPage,
          isInitialLoading: false,
          isRefreshing: false,
          isPassiveSyncing: false,
          syncStatus: NotificationSyncStatus.synced,
          clearInfoMessage: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      _setState(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isPassiveSyncing: false,
          syncStatus: NotificationSyncStatus.failed,
          clearInfoMessage: true,
          errorMessage: _resolveErrorMessage(
            error,
            operation: NotificationErrorOperation.loadNotifications,
          ),
        ),
      );
    } finally {
      _drainPendingLifecycleRefresh();
    }
  }

  Future<void> refresh() async {
    _setState(
      state.copyWith(
        isRefreshing: true,
        isPassiveSyncing: false,
        syncStatus: NotificationSyncStatus.syncing,
        clearInfoMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final results = await Future.wait<Object>([
        _getNotificationsUseCase(
          filter: NotificationListFilter(
            pageNumber: 1,
            pageSize: _defaultPageSize,
          ),
        ),
        _requestUnreadCount(),
      ]);

      final listResult = results[0] as NotificationListPageResult;
      final unreadCount = results[1] as int;
      final dedupedItems = _dedupeById(listResult.notifications);

      _setState(
        state.copyWith(
          items: List<NotificationListItem>.unmodifiable(dedupedItems),
          unreadCount: unreadCount,
          totalCount: listResult.totalCount,
          pageNumber: listResult.pageNumber,
          pageSize: listResult.pageSize,
          totalPages: listResult.totalPages,
          hasPreviousPage: listResult.hasPreviousPage,
          hasNextPage: listResult.hasNextPage,
          isRefreshing: false,
          isPassiveSyncing: false,
          syncStatus: NotificationSyncStatus.synced,
          clearInfoMessage: true,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      _setState(
        state.copyWith(
          isRefreshing: false,
          isPassiveSyncing: false,
          syncStatus: NotificationSyncStatus.failed,
          clearInfoMessage: true,
          errorMessage: _resolveErrorMessage(
            error,
            operation: NotificationErrorOperation.refreshNotifications,
          ),
        ),
      );
    } finally {
      _drainPendingLifecycleRefresh();
    }
  }

  Future<void> loadMore() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    _setState(state.copyWith(isLoadingMore: true, clearInfoMessage: true, clearErrorMessage: true));

    try {
      final nextPageResult = await _getNotificationsUseCase(
        filter: NotificationListFilter(
          pageNumber: state.pageNumber + 1,
          pageSize: state.pageSize,
        ),
      );

      final merged = _mergeById(state.items, nextPageResult.notifications);
      _setState(
        state.copyWith(
          items: List<NotificationListItem>.unmodifiable(merged),
          totalCount: nextPageResult.totalCount,
          pageNumber: nextPageResult.pageNumber,
          pageSize: nextPageResult.pageSize,
          totalPages: nextPageResult.totalPages,
          hasPreviousPage: nextPageResult.hasPreviousPage,
          hasNextPage: nextPageResult.hasNextPage,
          isLoadingMore: false,
          syncStatus: NotificationSyncStatus.synced,
          clearInfoMessage: true,
        ),
      );
    } catch (error) {
      _setState(
        state.copyWith(
          isLoadingMore: false,
          syncStatus: NotificationSyncStatus.failed,
          clearInfoMessage: true,
          errorMessage: _resolveErrorMessage(
            error,
            operation: NotificationErrorOperation.loadMoreNotifications,
          ),
        ),
      );
    }
  }

  Future<void> reloadUnreadCount() async {
    try {
      final unreadCount = await _requestUnreadCount();
      _setState(state.copyWith(unreadCount: unreadCount));
    } catch (error) {
      _setState(
        state.copyWith(
          syncStatus: NotificationSyncStatus.stale,
          errorMessage: _resolveErrorMessage(
            error,
            operation: NotificationErrorOperation.syncUnreadCount,
          ),
        ),
      );
    }
  }

  Future<int> _requestUnreadCount() {
    final runningRequest = _inFlightUnreadRequest;
    if (runningRequest != null) {
      return runningRequest;
    }

    final nextRequest = _getUnreadCountUseCase();
    _inFlightUnreadRequest = nextRequest;
    return nextRequest.whenComplete(() {
      _inFlightUnreadRequest = null;
    });
  }

  Future<void> markAsRead({required NotificationListItem item}) async {
    final notificationId = item.notificationId;
    if (state.markingIds.contains(notificationId) || (item.isRead ?? false)) {
      return;
    }

    final nextMarkingIds = Set<int>.from(state.markingIds)..add(notificationId);
    _setState(
      state.copyWith(
        markingIds: nextMarkingIds,
        clearInfoMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _markAsReadUseCase(notificationId: notificationId);

      final updatedItems = state.items
          .map(
            (current) => current.notificationId == notificationId
                ? NotificationListItem(
                    notificationId: current.notificationId,
                    title: current.title,
                    content: current.content,
                    notificationType: current.notificationType,
                    priority: current.priority,
                    isRead: true,
                    readDate: current.readDate ?? DateTime.now(),
                    actionUrl: current.actionUrl,
                    eventId: current.eventId,
                    eventName: current.eventName,
                    createdDate: current.createdDate,
                    expiryDate: current.expiryDate,
                  )
                : current,
          )
          .toList(growable: false);

      final afterMarkingIds = Set<int>.from(state.markingIds)
        ..remove(notificationId);
      _setState(
        state.copyWith(
          items: List<NotificationListItem>.unmodifiable(updatedItems),
          markingIds: afterMarkingIds,
          syncStatus: NotificationSyncStatus.synced,
          clearInfoMessage: true,
        ),
      );

      await reloadUnreadCount();
    } catch (error) {
      final afterMarkingIds = Set<int>.from(state.markingIds)
        ..remove(notificationId);
      _setState(
        state.copyWith(
          markingIds: afterMarkingIds,
          syncStatus: NotificationSyncStatus.failed,
          clearInfoMessage: true,
          errorMessage: _resolveErrorMessage(
            error,
            operation: NotificationErrorOperation.markAsRead,
          ),
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    if (state.isMarkingAllAsRead || state.items.isEmpty) {
      return;
    }

    _setState(
      state.copyWith(
        isMarkingAllAsRead: true,
        clearInfoMessage: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _markAllAsReadUseCase();
      _setState(state.copyWith(isMarkingAllAsRead: false));
      await refresh();
    } catch (error) {
      _setState(
        state.copyWith(
          isMarkingAllAsRead: false,
          syncStatus: NotificationSyncStatus.failed,
          clearInfoMessage: true,
          errorMessage: _resolveErrorMessage(
            error,
            operation: NotificationErrorOperation.markAllAsRead,
          ),
        ),
      );
    }
  }

  void clearError() {
    _setState(state.copyWith(clearErrorMessage: true));
  }

  void clearInfoMessage() {
    _setState(state.copyWith(clearInfoMessage: true));
  }

  void setReadFilter(NotificationReadFilter filter) {
    if (state.readFilter == filter) {
      return;
    }
    _setState(state.copyWith(readFilter: filter));
  }

  void applyIncomingPush({
    required NotificationListItem item,
    int? unreadCount,
  }) {
    final dedupedItems = _prependUniqueById(state.items, item);
    _setState(
      state.copyWith(
        items: List<NotificationListItem>.unmodifiable(dedupedItems),
        unreadCount: unreadCount ?? state.unreadCount,
        totalCount: _resolveTotalCountAfterPush(
          hadExistingItem: state.items.any(
            (current) => current.notificationId == item.notificationId,
          ),
        ),
        infoMessage: 'Bạn vừa nhận được thông báo mới.',
        clearErrorMessage: true,
      ),
    );
  }

  void _setState(NotificationState nextState) {
    if (_isDisposed) {
      return;
    }
    state = nextState;
    _onUnreadCountChanged(nextState.unreadCount);
  }

  String _resolveErrorMessage(
    Object error, {
    required NotificationErrorOperation operation,
  }) {
    return NotificationErrorUiMapper.message(error, operation: operation);
  }

  List<NotificationListItem> _mergeById(
    List<NotificationListItem> currentItems,
    List<NotificationListItem> incomingItems,
  ) {
    final mergedById = <int, NotificationListItem>{
      for (final item in currentItems) item.notificationId: item,
    };
    for (final item in incomingItems) {
      mergedById[item.notificationId] = item;
    }
    return mergedById.values.toList(growable: false);
  }

  List<NotificationListItem> _dedupeById(List<NotificationListItem> items) {
    final dedupedById = <int, NotificationListItem>{};
    for (final item in items) {
      dedupedById[item.notificationId] = item;
    }
    return dedupedById.values.toList(growable: false);
  }

  List<NotificationListItem> _prependUniqueById(
    List<NotificationListItem> currentItems,
    NotificationListItem incomingItem,
  ) {
    final merged = <NotificationListItem>[incomingItem];
    for (final item in currentItems) {
      if (item.notificationId == incomingItem.notificationId) {
        continue;
      }
      merged.add(item);
    }
    return merged;
  }

  int _resolveTotalCountAfterPush({required bool hadExistingItem}) {
    if (hadExistingItem) {
      return state.totalCount;
    }
    return state.totalCount + 1;
  }

  void _scheduleLifecycleRefresh() {
    if (state.isInitialLoading ||
        state.isRefreshing ||
        _isLifecycleRefreshRunning) {
      _hasPendingLifecycleRefresh = true;
      return;
    }
    unawaited(_runLifecycleRefresh());
  }

  Future<void> _runLifecycleRefresh() async {
    if (_isLifecycleRefreshRunning) {
      _hasPendingLifecycleRefresh = true;
      return;
    }
    _isLifecycleRefreshRunning = true;
    try {
      _hasPendingLifecycleRefresh = false;
      await _refreshFromLifecycle();
    } finally {
      _isLifecycleRefreshRunning = false;
      _drainPendingLifecycleRefresh();
    }
  }

  void _drainPendingLifecycleRefresh() {
    if (!_hasPendingLifecycleRefresh) {
      return;
    }
    if (state.isInitialLoading ||
        state.isRefreshing ||
        _isLifecycleRefreshRunning) {
      return;
    }
    unawaited(_runLifecycleRefresh());
  }

  static void _noopUnreadCountSync(int _) {}

  Future<void> _refreshFromLifecycle() async {
    final previousItems = List<NotificationListItem>.from(state.items);
    final previousUnreadCount = state.unreadCount;

    _setState(
      state.copyWith(
        isPassiveSyncing: true,
        syncStatus: NotificationSyncStatus.syncing,
        clearErrorMessage: true,
      ),
    );

    try {
      final results = await Future.wait<Object>([
        _getNotificationsUseCase(
          filter: NotificationListFilter(
            pageNumber: 1,
            pageSize: _defaultPageSize,
          ),
        ),
        _requestUnreadCount(),
      ]);

      final listResult = results[0] as NotificationListPageResult;
      final unreadCount = results[1] as int;
      final dedupedItems = _dedupeById(listResult.notifications);
      final infoMessage = _buildLifecycleInfoMessage(
        previousItems: previousItems,
        nextItems: dedupedItems,
        previousUnreadCount: previousUnreadCount,
        nextUnreadCount: unreadCount,
      );

      _setState(
        state.copyWith(
          items: List<NotificationListItem>.unmodifiable(dedupedItems),
          unreadCount: unreadCount,
          totalCount: listResult.totalCount,
          pageNumber: listResult.pageNumber,
          pageSize: listResult.pageSize,
          totalPages: listResult.totalPages,
          hasPreviousPage: listResult.hasPreviousPage,
          hasNextPage: listResult.hasNextPage,
          isPassiveSyncing: false,
          syncStatus: NotificationSyncStatus.synced,
          infoMessage: infoMessage,
          clearErrorMessage: true,
          clearInfoMessage: infoMessage == null,
        ),
      );
    } catch (error) {
      _setState(
        state.copyWith(
          isPassiveSyncing: false,
          syncStatus: NotificationSyncStatus.stale,
          clearInfoMessage: true,
          errorMessage: _resolveErrorMessage(
            error,
            operation: NotificationErrorOperation.refreshNotifications,
          ),
        ),
      );
    }
  }

  String? _buildLifecycleInfoMessage({
    required List<NotificationListItem> previousItems,
    required List<NotificationListItem> nextItems,
    required int previousUnreadCount,
    required int nextUnreadCount,
  }) {
    final previousIds = previousItems
        .map((item) => item.notificationId)
        .toSet();
    final hasNewNotification = nextItems.any(
      (item) => !previousIds.contains(item.notificationId),
    );

    if (hasNewNotification || nextUnreadCount > previousUnreadCount) {
      return 'Đã cập nhật thông báo mới.';
    }

    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _lifecycleSyncSubscription?.cancel();
    super.dispose();
  }
}
