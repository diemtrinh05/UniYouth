import '../../../../domain/repositories/notifications/notification_repository.dart';

enum NotificationSyncStatus {
  idle,
  syncing,
  synced,
  stale,
  failed,
}

enum NotificationReadFilter {
  all,
  unread,
  read,
}

class NotificationState {
  const NotificationState({
    this.items = const <NotificationListItem>[],
    this.unreadCount = 0,
    this.totalCount = 0,
    this.pageNumber = 1,
    this.pageSize = 20,
    this.totalPages = 1,
    this.hasPreviousPage = false,
    this.hasNextPage = false,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isPassiveSyncing = false,
    this.isMarkingAllAsRead = false,
    this.markingIds = const <int>{},
    this.readFilter = NotificationReadFilter.all,
    this.syncStatus = NotificationSyncStatus.idle,
    this.infoMessage,
    this.errorMessage,
  });

  final List<NotificationListItem> items;
  final int unreadCount;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isPassiveSyncing;
  final bool isMarkingAllAsRead;
  final Set<int> markingIds;
  final NotificationReadFilter readFilter;
  final NotificationSyncStatus syncStatus;
  final String? infoMessage;
  final String? errorMessage;

  bool get isEmpty => items.isEmpty;

  NotificationState copyWith({
    List<NotificationListItem>? items,
    int? unreadCount,
    int? totalCount,
    int? pageNumber,
    int? pageSize,
    int? totalPages,
    bool? hasPreviousPage,
    bool? hasNextPage,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isPassiveSyncing,
    bool? isMarkingAllAsRead,
    Set<int>? markingIds,
    NotificationReadFilter? readFilter,
    NotificationSyncStatus? syncStatus,
    String? infoMessage,
    String? errorMessage,
    bool clearInfoMessage = false,
    bool clearErrorMessage = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      totalCount: totalCount ?? this.totalCount,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isPassiveSyncing: isPassiveSyncing ?? this.isPassiveSyncing,
      isMarkingAllAsRead: isMarkingAllAsRead ?? this.isMarkingAllAsRead,
      markingIds: markingIds ?? this.markingIds,
      readFilter: readFilter ?? this.readFilter,
      syncStatus: syncStatus ?? this.syncStatus,
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
