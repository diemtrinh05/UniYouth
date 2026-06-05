import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/presentation/app/providers/app_provider_graph.dart';
import 'package:uniyouth_app/presentation/features/notifications/state/notification_provider.dart';
import 'package:uniyouth_app/presentation/navigation/main_navigation_shell.dart';
import 'package:uniyouth_app/presentation/navigation/tab_navigation_coordinator.dart';

import '../../test_support/provider_overrides.dart';

void main() {
  testWidgets('keeps tab state when switching tabs in app shell', (
    tester,
  ) async {
    final coordinator = AppShellTabNavigationCoordinator();
    final apiConfigService = await createTestApiConfigService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigServiceProvider.overrideWithValue(apiConfigService),
        ],
        child: MaterialApp(
          home: MainNavigationShell(
            tabNavigationCoordinator: coordinator,
            homeTab: const _CounterTab(
              title: 'HOME_TAB',
              buttonLabel: 'Increment Home',
            ),
            eventsTab: const _StaticTab(title: 'EVENTS_TAB'),
            pointsTab: const _StaticTab(title: 'POINTS_TAB'),
            profileTab: const _StaticTab(title: 'PROFILE_TAB'),
            onQrTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('HOME_TAB: 0'), findsOneWidget);

    await tester.tap(find.text('Increment Home'));
    await tester.pump();
    expect(find.text('HOME_TAB: 1'), findsOneWidget);

    await tester.tap(find.text('Sự kiện'));
    await tester.pumpAndSettle();
    expect(find.text('EVENTS_TAB'), findsOneWidget);

    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    expect(find.text('HOME_TAB: 1'), findsOneWidget);
  });

  testWidgets('back from non-home tab returns user to home tab first', (
    tester,
  ) async {
    final coordinator = AppShellTabNavigationCoordinator();
    final apiConfigService = await createTestApiConfigService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigServiceProvider.overrideWithValue(apiConfigService),
        ],
        child: MaterialApp(
          home: MainNavigationShell(
            tabNavigationCoordinator: coordinator,
            homeTab: const _StaticTab(title: 'HOME_ROOT'),
            eventsTab: const _StaticTab(title: 'EVENTS_ROOT'),
            pointsTab: const _StaticTab(title: 'POINTS_ROOT'),
            profileTab: const _StaticTab(title: 'PROFILE_ROOT'),
            onQrTap: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Điểm số'));
    await tester.pumpAndSettle();

    expect(find.text('POINTS_ROOT'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('HOME_ROOT'), findsOneWidget);
  });

  testWidgets('initialIndex opens the requested tab without provider assertion', (
    tester,
  ) async {
    final coordinator = AppShellTabNavigationCoordinator();
    final apiConfigService = await createTestApiConfigService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigServiceProvider.overrideWithValue(apiConfigService),
        ],
        child: MaterialApp(
          home: MainNavigationShell(
            tabNavigationCoordinator: coordinator,
            homeTab: const _StaticTab(title: 'HOME_ROOT'),
            eventsTab: const _StaticTab(title: 'EVENTS_ROOT'),
            pointsTab: const _StaticTab(title: 'POINTS_ROOT'),
            profileTab: const _StaticTab(title: 'PROFILE_ROOT'),
            initialIndex: 2,
            onQrTap: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('POINTS_ROOT'), findsOneWidget);
  });

  testWidgets('nested tab route stays in tab stack across tab switching', (
    tester,
  ) async {
    final coordinator = AppShellTabNavigationCoordinator();
    final apiConfigService = await createTestApiConfigService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigServiceProvider.overrideWithValue(apiConfigService),
        ],
        child: MaterialApp(
          home: MainNavigationShell(
            tabNavigationCoordinator: coordinator,
            homeTab: const _StaticTab(title: 'HOME_ROOT'),
            eventsTab: const _StaticTab(title: 'EVENTS_ROOT'),
            pointsTab: _TestNestedTabNavigator(
              navigatorKey: coordinator.pointsNavigatorKey,
              rootTitle: 'POINTS_ROOT',
              detailTitle: 'POINTS_DETAIL',
            ),
            profileTab: const _StaticTab(title: 'PROFILE_ROOT'),
            onQrTap: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Điểm số'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();

    expect(find.text('POINTS_DETAIL'), findsOneWidget);

    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Điểm số'));
    await tester.pumpAndSettle();

    expect(find.text('POINTS_DETAIL'), findsOneWidget);
  });

  testWidgets('back pops nested tab route before switching back to home', (
    tester,
  ) async {
    final coordinator = AppShellTabNavigationCoordinator();
    final apiConfigService = await createTestApiConfigService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigServiceProvider.overrideWithValue(apiConfigService),
        ],
        child: MaterialApp(
          home: MainNavigationShell(
            tabNavigationCoordinator: coordinator,
            homeTab: const _StaticTab(title: 'HOME_ROOT'),
            eventsTab: const _StaticTab(title: 'EVENTS_ROOT'),
            pointsTab: _TestNestedTabNavigator(
              navigatorKey: coordinator.pointsNavigatorKey,
              rootTitle: 'POINTS_ROOT',
              detailTitle: 'POINTS_DETAIL',
            ),
            profileTab: const _StaticTab(title: 'PROFILE_ROOT'),
            onQrTap: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Điểm số'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('POINTS_ROOT'), findsOneWidget);
    expect(find.text('HOME_ROOT'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('HOME_ROOT'), findsOneWidget);
  });

  testWidgets('reselecting active tab pops nested tab stack to its root', (
    tester,
  ) async {
    final coordinator = AppShellTabNavigationCoordinator();
    final apiConfigService = await createTestApiConfigService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigServiceProvider.overrideWithValue(apiConfigService),
        ],
        child: MaterialApp(
          home: MainNavigationShell(
            tabNavigationCoordinator: coordinator,
            homeTab: const _StaticTab(title: 'HOME_ROOT'),
            eventsTab: _TestNestedTabNavigator(
              navigatorKey: coordinator.eventsNavigatorKey,
              rootTitle: 'EVENTS_ROOT',
              detailTitle: 'EVENTS_DETAIL',
            ),
            pointsTab: const _StaticTab(title: 'POINTS_ROOT'),
            profileTab: const _StaticTab(title: 'PROFILE_ROOT'),
            onQrTap: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sự kiện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();

    expect(find.text('EVENTS_DETAIL'), findsOneWidget);

    await tester.tap(find.text('Sự kiện'));
    await tester.pumpAndSettle();

    expect(find.text('EVENTS_ROOT'), findsOneWidget);
    expect(find.text('EVENTS_DETAIL'), findsNothing);
    expect(find.text('HOME_ROOT'), findsNothing);
  });

  testWidgets('shell does not overlay notification entry across tabs', (
    tester,
  ) async {
    final coordinator = AppShellTabNavigationCoordinator();
    final apiConfigService = await createTestApiConfigService();
    final unreadSyncController = NotificationUnreadSyncController(
      reloadUnreadCount: () async {},
      lifecycleSyncStream: const Stream<void>.empty(),
    );
    final container = ProviderContainer(
      overrides: [
        apiConfigServiceProvider.overrideWithValue(apiConfigService),
        notificationUnreadSyncControllerProvider.overrideWithValue(
          unreadSyncController,
        ),
      ],
    );
    addTearDown(() {
      unreadSyncController.dispose();
      container.dispose();
    });
    container.read(notificationUnreadCountProvider.notifier).setUnreadCount(7);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MainNavigationShell(
            tabNavigationCoordinator: coordinator,
            homeTab: const _StaticTab(title: 'HOME_ROOT'),
            eventsTab: const _StaticTab(title: 'EVENTS_ROOT'),
            pointsTab: const _StaticTab(title: 'POINTS_ROOT'),
            profileTab: const _StaticTab(title: 'PROFILE_ROOT'),
            onQrTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(find.text('7'), findsNothing);

    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(find.text('7'), findsNothing);
  });
}

class _StaticTab extends StatelessWidget {
  const _StaticTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}

class _CounterTab extends StatefulWidget {
  const _CounterTab({
    required this.title,
    required this.buttonLabel,
  });

  final String title;
  final String buttonLabel;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.title}: $_count'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _count += 1;
                });
              },
              child: Text(widget.buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestNestedTabNavigator extends StatelessWidget {
  const _TestNestedTabNavigator({
    required this.navigatorKey,
    required this.rootTitle,
    required this.detailTitle,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final String rootTitle;
  final String detailTitle;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        if (settings.name == Navigator.defaultRouteName) {
          return MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(rootTitle),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/detail');
                      },
                      child: const Text('Open detail'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (settings.name == '/detail') {
          return MaterialPageRoute<void>(
            builder: (context) =>
                Scaffold(body: Center(child: Text(detailTitle))),
          );
        }

        return null;
      },
    );
  }
}
