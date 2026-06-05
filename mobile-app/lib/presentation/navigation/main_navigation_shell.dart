import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/state/notification_provider.dart';
import 'bottom_navigation.dart';
import 'state/navigation_shell_provider.dart';
import 'tab_navigation_coordinator.dart';

const _kQrFabCyan = Color(0xFF00BCD4);

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({
    super.key,
    required this.homeTab,
    required this.eventsTab,
    required this.pointsTab,
    required this.profileTab,
    this.initialIndex = 0,
    required this.onQrTap,
    required this.tabNavigationCoordinator,
  });

  final Widget homeTab;
  final Widget eventsTab;
  final Widget pointsTab;
  final Widget profileTab;
  final int initialIndex;
  final VoidCallback onQrTap;
  final AppShellTabNavigationCoordinator tabNavigationCoordinator;

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  static const _tabs = <BottomNavigationTabItem>[
    BottomNavigationTabItem(
      label: 'Trang chủ',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
    ),
    BottomNavigationTabItem(
      label: 'Sự kiện',
      activeIcon: Icons.event_rounded,
      inactiveIcon: Icons.event_outlined,
    ),
    BottomNavigationTabItem(
      label: 'Điểm số',
      activeIcon: Icons.stars_rounded,
      inactiveIcon: Icons.stars_outlined,
    ),
    BottomNavigationTabItem(
      label: 'Hồ sơ',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outlined,
    ),
  ];

  NavigationShellTab? _pendingInitialTab;
  int _initialTabSyncToken = 0;

  @override
  void initState() {
    super.initState();
    _queueInitialTabSync(widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(notificationUnreadSyncControllerProvider).syncUnreadCount();
    });
  }

  @override
  void didUpdateWidget(covariant MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _queueInitialTabSync(widget.initialIndex);
    }
  }

  void _queueInitialTabSync(int index) {
    final targetTab = navigationShellTabFromIndex(index);
    _initialTabSyncToken += 1;
    final syncToken = _initialTabSyncToken;
    _pendingInitialTab = targetTab;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || syncToken != _initialTabSyncToken) {
        return;
      }

      ref.read(navigationShellNotifierProvider.notifier).selectTab(targetTab);
      if (!mounted || _pendingInitialTab != targetTab) {
        return;
      }

      setState(() {
        _pendingInitialTab = null;
      });
    });
  }

  void _cancelPendingInitialTabSync() {
    _initialTabSyncToken += 1;
    if (_pendingInitialTab == null) {
      return;
    }

    setState(() {
      _pendingInitialTab = null;
    });
  }

  void _onSelectTab(int index) {
    _cancelPendingInitialTabSync();
    final targetTab = navigationShellTabFromIndex(index);
    final currentTab = _pendingInitialTab ??
        ref.read(navigationShellNotifierProvider).selectedTab;

    if (currentTab == targetTab) {
      if (widget.tabNavigationCoordinator.canPopToRootInTab(targetTab)) {
        widget.tabNavigationCoordinator.popToRootInTab(targetTab);
      }
      return;
    }

    ref.read(navigationShellNotifierProvider.notifier).selectTab(targetTab);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationUnreadSyncControllerProvider);
    final providerSelectedTab = ref.watch(
      navigationShellNotifierProvider.select((state) => state.selectedTab),
    );
    final selectedTab = _pendingInitialTab ?? providerSelectedTab;
    final selectedIndex = selectedTab.index;

    return PopScope(
      canPop: selectedTab == NavigationShellTab.home,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || selectedTab == NavigationShellTab.home) {
          return;
        }

        if (widget.tabNavigationCoordinator.canPopInTab(selectedTab)) {
          widget.tabNavigationCoordinator.popInTab(selectedTab);
          return;
        }

        _cancelPendingInitialTabSync();
        ref
            .read(navigationShellNotifierProvider.notifier)
            .selectTab(NavigationShellTab.home);
      },
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: [
            widget.homeTab,
            widget.eventsTab,
            widget.pointsTab,
            widget.profileTab,
          ],
        ),
        floatingActionButton: Tooltip(
          message: 'QR Scan',
          child: GestureDetector(
            onTap: widget.onQrTap,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kQrFabCyan, Color(0xFF0097A7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kQrFabCyan.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: UniYouthBottomNavigation(
          tabs: _tabs,
          selectedIndex: selectedIndex,
          onSelectTab: _onSelectTab,
        ),
      ),
    );
  }
}
