import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../app/router/app_routes.dart';
import '../../app/providers/app_provider_graph.dart';
import '../../navigation/state/navigation_shell_provider.dart';
import '../notifications/state/notification_provider.dart';
import '../../../../../domain/usecases/events/get_home_event_preview_usecase.dart';
import '../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../shared/formatters/date_time_formatter.dart';
import '../../shared/mappers/event_status_ui_mapper.dart';
import 'home/state/home_dashboard_notifier.dart';
import 'home/state/home_dashboard_provider.dart';
import 'home/state/home_dashboard_state.dart';
import 'home/state/home_event_preview_notifier.dart';
import 'home/state/home_event_preview_provider.dart';
import 'home/state/home_event_preview_state.dart';

// --- Design Tokens ---
const _kBlue = Color(0xFF1565C0);
const _kBlueDark = Color(0xFF0D47A1);
const _kBlueMid = Color(0xFF1976D2);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kCyan = Color(0xFF00BCD4);
const _kSurface = Colors.white;
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);

bool _isInsideAppShell(BuildContext context) =>
    ModalRoute.of(context)?.settings.name == AppRoutes.app;

void _openPrimaryDestinationTab({
  required BuildContext context,
  required WidgetRef ref,
  required NavigationShellTab tab,
}) {
  if (_isInsideAppShell(context)) {
    ref.read(navigationShellNotifierProvider.notifier).selectTab(tab);
    return;
  }

  Navigator.of(context).pushReplacementNamed(AppRoutes.app, arguments: tab);
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onLogout,
    required this.getMyProfileUseCase,
    required this.getHomeEventPreviewUseCase,
  });

  final Future<void> Function() onLogout;
  final GetMyProfileUseCase getMyProfileUseCase;
  final GetHomeEventPreviewUseCase getHomeEventPreviewUseCase;

  @override
  Widget build(BuildContext context) {
    return HomeDashboardContent(
      onLogout: onLogout,
      getMyProfileUseCase: getMyProfileUseCase,
      getHomeEventPreviewUseCase: getHomeEventPreviewUseCase,
      showNotificationEntry: true,
    );
  }
}

// --- Dashboard Content --------------------------------------------------------
class HomeDashboardContent extends ConsumerStatefulWidget {
  const HomeDashboardContent({
    super.key,
    required this.onLogout,
    required this.getMyProfileUseCase,
    required this.getHomeEventPreviewUseCase,
    this.showNotificationEntry = true,
  });
  final Future<void> Function() onLogout;
  final GetMyProfileUseCase getMyProfileUseCase;
  final GetHomeEventPreviewUseCase getHomeEventPreviewUseCase;
  final bool showNotificationEntry;

  @override
  ConsumerState<HomeDashboardContent> createState() =>
      _HomeDashboardContentState();
}

class _HomeDashboardContentState extends ConsumerState<HomeDashboardContent>
    with TickerProviderStateMixin {
  static const _scrollStorageKey = PageStorageKey<String>(
    'home_dashboard_scroll',
  );

  late final HomeDashboardNotifierDependencies _homeDashboardDependencies;
  late final StateNotifierProvider<HomeDashboardNotifier, HomeDashboardState>
  _homeDashboardStateProvider;
  late final HomeEventPreviewNotifierDependencies _homeEventPreviewDependencies;
  late final StateNotifierProvider<
    HomeEventPreviewNotifier,
    HomeEventPreviewState
  >
  _homeEventPreviewStateProvider;

  late AnimationController _staggerCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;
  bool _hasShownFaceEnrollmentReminderDialog = false;

  static const _quickActions = [
    _QuickAction(
      Icons.history_rounded,
      'Lịch sử\nĐiểm danh',
      AppRoutes.attendanceHistory,
      Color(0xFF0288D1),
    ),
    _QuickAction(
      Icons.notifications_rounded,
      'Thông báo',
      AppRoutes.notifications,
      Color(0xFF006064),
    ),
    _QuickAction(
      Icons.category_rounded,
      'Danh mục\nSự kiện',
      AppRoutes.eventFilters,
      Color(0xFF1565C0),
    ),
    _QuickAction(
      Icons.history_edu_rounded,
      'Lịch sử\nĐiểm số',
      AppRoutes.pointsHistory,
      Color(0xFF00695C),
    ),
    _QuickAction(
      Icons.support_agent_rounded,
      'Hỗ trợ\nSinh viên',
      AppRoutes.supportChat,
      Color(0xFF5E35B1),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(6, (i) {
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(6, (i) {
      final start = i * 0.1;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _homeDashboardDependencies = HomeDashboardNotifierDependencies(
      getMyProfileUseCase: widget.getMyProfileUseCase,
      onLogout: widget.onLogout,
    );
    _homeDashboardStateProvider = homeDashboardNotifierByDependenciesProvider(
      _homeDashboardDependencies,
    );
    _homeEventPreviewDependencies = HomeEventPreviewNotifierDependencies(
      getHomeEventPreviewUseCase: widget.getHomeEventPreviewUseCase,
    );
    _homeEventPreviewStateProvider =
        homeEventPreviewNotifierByDependenciesProvider(
          _homeEventPreviewDependencies,
        );
    _staggerCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncProfile();
      unawaited(_loadHomeEventPreview());
      if (widget.showNotificationEntry) {
        ref.read(notificationUnreadSyncControllerProvider).syncUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  // -- Load profile để lấy tên & avatar --------------------------------------
  Future<void> _syncProfile() async {
    await ref.read(_homeDashboardStateProvider.notifier).syncProfile();
    if (!mounted || _hasShownFaceEnrollmentReminderDialog) {
      return;
    }

    final dashboardState = ref.read(_homeDashboardStateProvider);
    if (dashboardState.isLoadingProfile ||
        dashboardState.hasActiveFaceProfile) {
      return;
    }

    _hasShownFaceEnrollmentReminderDialog = true;
    await _showFaceEnrollmentReminderDialog();
  }

  Future<void> _loadHomeEventPreview() =>
      ref.read(_homeEventPreviewStateProvider.notifier).loadPreview();

  Future<void> _logout() async {
    await ref.read(_homeDashboardStateProvider.notifier).logout();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).pushNamed(AppRoutes.notifications);
  }

  void _openEventsTab() {
    _openPrimaryDestinationTab(
      context: context,
      ref: ref,
      tab: NavigationShellTab.events,
    );
  }

  void _openProfileTab() {
    _openPrimaryDestinationTab(
      context: context,
      ref: ref,
      tab: NavigationShellTab.profile,
    );
  }

  Future<void> _showFaceEnrollmentReminderDialog() async {
    final shouldOpenProfile = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kBlueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.face_retouching_natural_rounded,
                  color: _kBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Bạn chưa đăng ký khuôn mặt',
                    style: TextStyle(
                      color: _kTextDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                icon: const Icon(Icons.close_rounded, color: _kTextMid),
              ),
            ],
          ),
          content: const Text(
            'Hãy đăng ký khuôn mặt để dùng check-in bằng face nhanh hơn và ổn định hơn trong các sự kiện có bật xác minh khuôn mặt.',
            style: TextStyle(color: _kTextMid, fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Để sau'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text(
                'Đăng ký ngay',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (shouldOpenProfile == true && mounted) {
      _openProfileTab();
    }
  }

  Future<void> _openEventDetail(int eventId) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.eventDetail, arguments: eventId);
  }

  Widget _animated(int i, Widget child) => FadeTransition(
    opacity: _fadeAnims[i],
    child: SlideTransition(position: _slideAnims[i], child: child),
  );

  /// Lấy tên ngắn (tên + đệm cuối) để hiển thị lời chào gọn
  String _shortName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 2) return fullName;
    // Họ + tên (bỏ đệm ở giữa) → VD: "Nguyễn Văn An" → "An"
    return parts.last;
  }

  /// Chọn lời chào theo giờ trong ngày
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showNotificationEntry) {
      ref.watch(notificationUnreadSyncControllerProvider);
    }
    final dashboardState = ref.watch(_homeDashboardStateProvider);
    final homeEventPreviewState = ref.watch(_homeEventPreviewStateProvider);

    return CustomScrollView(
      key: _scrollStorageKey,
      slivers: [
        SliverToBoxAdapter(child: _animated(0, _buildHeader(dashboardState))),
        SliverToBoxAdapter(child: _animated(1, _buildHeroBanner())),
        SliverToBoxAdapter(
          child: _animated(
            2,
            _SectionTitle(
              title: 'Hoạt động nhanh',
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _animated(3, _QuickActionCard(action: _quickActions[index])),
              childCount: _quickActions.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _animated(
            4,
            _SectionTitle(
              title: 'Khám phá sự kiện',
              action: 'Xem tất cả',
              onAction: _openEventsTab,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _animated(5, _buildEventPreviewRow(homeEventPreviewState)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ─── Header với lời chào tên người dùng ─────────────────────────────────
  Widget _buildHeader(HomeDashboardState dashboardState) {
    final hasAvatar =
        dashboardState.avatarUrl != null &&
        dashboardState.avatarUrl!.isNotEmpty;
    final unreadCount = widget.showNotificationEntry
        ? ref.watch(notificationUnreadCountProvider)
        : 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -- Greeting + Name ----------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo pill nhỏ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_kBlue, _kBlueSky]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'UniYouth',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Lời chào
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kTextMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                // Tên người dùng
                dashboardState.isLoadingProfile
                    ? Container(
                        height: 22,
                        width: 140,
                        decoration: BoxDecoration(
                          color: _kBlueLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      )
                    : Text(
                        dashboardState.fullName != null &&
                                dashboardState.fullName!.isNotEmpty
                            ? '${_shortName(dashboardState.fullName!)}! 👋'
                            : 'Bạn ơi! 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _kTextDark,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
              ],
            ),
          ),

          // -- Notification bell --------------------------------------------
          if (widget.showNotificationEntry) ...[
            GestureDetector(
              onTap: _openNotifications,
              child: Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kBlue.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: _kTextDark,
                      size: 22,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],

          // -- Avatar / Logout -----------------------------------------------
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kBlue, _kCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        dashboardState.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                      )
                    : dashboardState.isLoadingProfile
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _logout();
  }

  Widget _buildHeroBanner() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.attendanceQrScan),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kBlueDark, _kBlueMid, Color(0xFF0288D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kBlue.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Hôm nay',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Quét QR\nĐiểm danh ngay!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: _kBlue,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Mở máy quét',
                          style: TextStyle(
                            color: _kBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Colors.white,
                size: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventPreviewSkeleton() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: _kBlueLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: _kBlueLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 90,
                  decoration: BoxDecoration(
                    color: _kBlueLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 24,
                  width: 76,
                  decoration: BoxDecoration(
                    color: _kBlueLight,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPreviewCard(HomeEventPreviewItem item) {
    final statusColor = EventStatusUiMapper.foregroundColor(item.status);
    final thumbnailUrl = (item.thumbnailUrl ?? '').trim();

    return GestureDetector(
      onTap: () => _openEventDetail(item.eventId),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: thumbnailUrl.isEmpty
                    ? Container(
                        color: _kBlueLight,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.event_rounded,
                          color: statusColor,
                          size: 28,
                        ),
                      )
                    : Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: _kBlueLight,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_outlined,
                            color: statusColor,
                            size: 28,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.eventName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateTimeFormatter.formatDate(item.startTime),
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _EventPreviewPill(
                          label: item.statusName ?? 'Không rõ',
                          color: statusColor,
                        ),
                        if (item.hasAvailableSlots)
                          const _EventPreviewPill(
                            label: 'Còn chỗ',
                            color: _kCyan,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventPreviewRow(HomeEventPreviewState state) {
    if (state.isLoading) {
      return SizedBox(
        height: 192,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _buildEventPreviewSkeleton(),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFCDD2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Không thể tải sự kiện nổi bật',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kTextMid,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _loadHomeEventPreview,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kBlueLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      color: _kBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.event_busy_rounded, color: _kBlueSky, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hiện chưa có sự kiện để khám phá',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kTextMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _buildEventPreviewCard(state.items[index]),
      ),
    );
  }
}

// --- Shared Widgets -----------------------------------------------------------
class _EventPreviewPill extends StatelessWidget {
  const _EventPreviewPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.onAction,
    required this.padding,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _kBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
            ),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kBlueSky,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.route, this.color);
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(action.route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: action.color.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                action.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
