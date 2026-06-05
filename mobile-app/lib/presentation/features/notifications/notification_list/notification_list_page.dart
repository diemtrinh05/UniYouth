import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/notifications/notification_navigation_handler.dart';
import '../../../../../domain/repositories/notifications/notification_repository.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/error_widgets/app_error_snackbar.dart';
import '../../../shared/error_widgets/app_error_view.dart';
import '../state/notification_provider.dart';
import '../state/notification_state.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);
const _kWarning = Color(0xFFF57C00);

class NotificationListPage extends ConsumerStatefulWidget {
  const NotificationListPage({super.key});

  @override
  ConsumerState<NotificationListPage> createState() =>
      _NotificationListPageState();
}

class _NotificationListPageState extends ConsumerState<NotificationListPage> {
  final ScrollController _scrollController = ScrollController();
  final NotificationNavigationHandler _navigationHandler =
      const NotificationNavigationHandler(
        notificationsRoute: AppRoutes.notifications,
        eventDetailRoute: AppRoutes.eventDetail,
        enableDebugLogs: false,
      );

  String? _lastErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(notificationNotifierProvider.notifier).syncInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onNotifierStateChanged({
    required String? errorMessage,
    required NotificationSyncStatus syncStatus,
    required bool hasItems,
  }) {
    if (errorMessage != null &&
        errorMessage != _lastErrorMessage &&
        hasItems &&
        syncStatus == NotificationSyncStatus.failed) {
      _showSnackBar(errorMessage);
    }

    _lastErrorMessage = errorMessage;
  }

  void _onScroll() {
    final state = ref.read(notificationNotifierProvider);
    if (state.isInitialLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= (position.maxScrollExtent - 200)) {
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _loadFirstPage() =>
      ref.read(notificationNotifierProvider.notifier).syncInitial();

  Future<void> _refresh() =>
      ref.read(notificationNotifierProvider.notifier).refresh();

  Future<void> _markOneAsRead(NotificationListItem item) async {
    await ref
        .read(notificationNotifierProvider.notifier)
        .markAsRead(item: item);
  }

  Future<void> _markAllAsRead() async {
    await ref.read(notificationNotifierProvider.notifier).markAllAsRead();
  }

  void _showSnackBar(String message) =>
      AppErrorSnackBar.show(context, message: message);

  int _sortNewestFirst(NotificationListItem a, NotificationListItem b) {
    final aTime = a.createdDate?.millisecondsSinceEpoch ?? 0;
    final bTime = b.createdDate?.millisecondsSinceEpoch ?? 0;
    return bTime.compareTo(aTime);
  }

  List<NotificationListItem> _sortedItems() {
    final sorted = List<NotificationListItem>.from(
      ref.read(notificationNotifierProvider.notifier).filteredItems,
    )..sort(_sortNewestFirst);
    return sorted;
  }

  NotificationNavigationTarget _resolveNavigationTarget(
    NotificationListItem item,
  ) {
    return _navigationHandler.resolveTarget(<String, dynamic>{
      if (item.eventId != null) 'eventId': item.eventId,
      if ((item.actionUrl ?? '').trim().isNotEmpty) 'actionUrl': item.actionUrl,
    });
  }

  int? _resolveNotificationEventId(NotificationListItem item) {
    final target = _resolveNavigationTarget(item);
    if (target.routeName != AppRoutes.eventDetail) {
      return null;
    }

    final rawArgument = target.arguments;
    if (rawArgument is int && rawArgument > 0) {
      return rawArgument;
    }

    return null;
  }

  Future<void> _openRelatedScreen(NotificationListItem item) async {
    final eventId = _resolveNotificationEventId(item);
    if (eventId == null) {
      _showSnackBar('Thông báo này chưa có màn hình liên kết.');
      return;
    }

    if (!(item.isRead ?? false)) {
      await _markOneAsRead(item);
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.eventDetail, arguments: eventId);
  }

  String _safeText(String? value, {String fallback = 'Không có dữ liệu'}) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? fallback : normalized;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Không có';
    }

    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _filterLabel(NotificationReadFilter filter) {
    switch (filter) {
      case NotificationReadFilter.all:
        return 'Tất cả';
      case NotificationReadFilter.unread:
        return 'Chưa đọc';
      case NotificationReadFilter.read:
        return 'Đã đọc';
    }
  }

  Widget _buildMarkAsReadButton({
    required NotificationState state,
    required NotificationListItem item,
  }) {
    final isMarking = state.markingIds.contains(item.notificationId);

    return GestureDetector(
      onTap: isMarking ? null : () => _markOneAsRead(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _kBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isMarking
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Đánh dấu đã đọc',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildReadFilterBar(NotificationState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NotificationReadFilter.values
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_filterLabel(filter)),
                  selected: state.readFilter == filter,
                  onSelected: (_) => ref
                      .read(notificationNotifierProvider.notifier)
                      .setReadFilter(filter),
                  selectedColor: _kBlueLight,
                  labelStyle: TextStyle(
                    color: state.readFilter == filter ? _kBlue : _kTextMid,
                    fontWeight: state.readFilter == filter
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: state.readFilter == filter
                        ? _kBlue.withValues(alpha: 0.4)
                        : _kTextMid.withValues(alpha: 0.2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildStatusCard(NotificationState state, List<NotificationListItem> items) {
    if (state.isPassiveSyncing && items.isNotEmpty) {
      return _InlineStatusCard(
        icon: Icons.sync_rounded,
        iconColor: _kBlue,
        backgroundColor: _kBlueLight,
        title: 'Đang đồng bộ thông báo mới',
        message: 'Danh sách sẽ tự cập nhật khi có push mới hoặc khi bạn quay lại ứng dụng.',
        trailing: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
        ),
      );
    }

    if (state.errorMessage != null && items.isNotEmpty) {
      return _InlineStatusCard(
        icon: Icons.warning_amber_rounded,
        iconColor: _kWarning,
        backgroundColor: const Color(0xFFFFF3E0),
        title: 'Không thể đồng bộ đầy đủ thông báo',
        message: state.errorMessage!,
        trailing: TextButton(
          onPressed: _refresh,
          child: const Text('Thử lại'),
        ),
      );
    }

    if (state.infoMessage != null && items.isNotEmpty) {
      return _InlineStatusCard(
        icon: Icons.notifications_active_outlined,
        iconColor: _kBlue,
        backgroundColor: _kBlueLight,
        title: 'Trạng thái đồng bộ',
        message: state.infoMessage!,
        trailing: IconButton(
          tooltip: 'Ẩn',
          onPressed: () => ref
              .read(notificationNotifierProvider.notifier)
              .clearInfoMessage(),
          icon: const Icon(Icons.close_rounded, size: 18, color: _kBlue),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _kBlue),
            SizedBox(height: 16),
            Text(
              'Đang tải thông báo...',
              style: TextStyle(
                color: _kTextDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng chờ trong giây lát để đồng bộ danh sách mới nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextMid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(NotificationState state) {
    final title = switch (state.readFilter) {
      NotificationReadFilter.all => 'Chưa có thông báo nào',
      NotificationReadFilter.unread => 'Không còn thông báo chưa đọc',
      NotificationReadFilter.read => 'Chưa có thông báo đã đọc',
    };

    final message = switch (state.readFilter) {
      NotificationReadFilter.all =>
        'Khi hệ thống có cập nhật mới, thông báo sẽ xuất hiện tại đây.',
      NotificationReadFilter.unread =>
        'Bạn đã đọc hết thông báo hoặc chưa có push mới cần xử lý.',
      NotificationReadFilter.read =>
        'Bạn chưa đánh dấu thông báo nào là đã đọc.',
    };

    return RefreshIndicator(
      onRefresh: _refresh,
      color: _kBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _buildReadFilterBar(state),
          const SizedBox(height: 12),
          _buildStatusCard(state, const <NotificationListItem>[]),
          const SizedBox(height: 72),
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.notifications_off_outlined,
                  color: _kBlueSky,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _kTextMid, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<(String?, NotificationSyncStatus, bool)>(
      notificationNotifierProvider.select(
        (state) => (
          state.errorMessage,
          state.syncStatus,
          state.items.isNotEmpty,
        ),
      ),
      (previous, next) {
        _onNotifierStateChanged(
          errorMessage: next.$1,
          syncStatus: next.$2,
          hasItems: next.$3,
        );
      },
    );

    ref.watch(
      notificationNotifierProvider.select(
        (state) => (
          state.items,
          state.unreadCount,
          state.totalCount,
          state.isInitialLoading,
          state.isRefreshing,
          state.isLoadingMore,
          state.isPassiveSyncing,
          state.isMarkingAllAsRead,
          state.markingIds,
          state.readFilter,
          state.infoMessage,
          state.errorMessage,
          state.syncStatus,
        ),
      ),
    );
    final state = ref.read(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Thông báo',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          GestureDetector(
            onTap: state.isMarkingAllAsRead ? null : _markAllAsRead,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kBlueLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: state.isMarkingAllAsRead
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _kBlue,
                      ),
                    )
                  : const Text(
                      'Đọc tất cả',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationState state) {
    final items = _sortedItems();

    if (state.isInitialLoading) {
      return _buildLoadingState();
    }

    if (state.errorMessage != null && items.isEmpty) {
      return AppErrorView(
        title: 'Không thể tải thông báo',
        message: state.errorMessage!,
        onRetry: _loadFirstPage,
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState(state);
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: _kBlue,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: items.length + (state.isLoadingMore ? 2 : 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReadFilterBar(state),
                const SizedBox(height: 10),
                _buildStatusCard(state, items),
                if (state.infoMessage != null ||
                    state.errorMessage != null ||
                    state.isPassiveSyncing)
                  const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    state.readFilter == NotificationReadFilter.all
                        ? '${state.totalCount} thông báo'
                        : '${items.length}/${state.totalCount} thông báo',
                    style: const TextStyle(
                      color: _kTextMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          }

          final itemIndex = index - 1;
          if (itemIndex >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: _kBlue)),
            );
          }

          return _buildNotificationCard(state, items[itemIndex]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationState state,
    NotificationListItem item,
  ) {
    final isRead = item.isRead ?? false;
    final resolvedEventId = _resolveNotificationEventId(item);
    final isActionable = resolvedEventId != null;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: isRead
            ? null
            : Border.all(color: _kBlue.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: isRead ? 0.05 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _safeText(item.title, fallback: 'Thông báo hệ thống'),
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                    fontSize: 13,
                    color: _kTextDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _safeText(item.content, fallback: 'Không có nội dung chi tiết.'),
            style: TextStyle(
              fontSize: 12,
              color: isRead ? _kTextMid : _kTextDark,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if ((item.eventName ?? '').trim().isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kBlueLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.eventName!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kBlue,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 11, color: _kTextMid),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatDateTime(item.createdDate),
                  style: const TextStyle(fontSize: 11, color: _kTextMid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!isRead) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _buildMarkAsReadButton(state: state, item: item),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isActionable
                    ? Icons.open_in_new_rounded
                    : Icons.info_outline_rounded,
                size: 12,
                color: isActionable ? _kBlueSky : _kTextMid,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isActionable
                      ? 'Mở sự kiện #$resolvedEventId'
                      : 'Thông báo này chưa có màn hình liên kết.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActionable ? _kBlueSky : _kTextMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isActionable) {
      return card;
    }

    return GestureDetector(
      onTap: () => _openRelatedScreen(item),
      child: card,
    );
  }
}

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.message,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: _kTextMid, height: 1.35),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
