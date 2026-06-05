import 'package:flutter/material.dart';

import '../app/router/app_routes.dart';
import 'state/navigation_shell_provider.dart';

class AppShellTabNavigationCoordinator {
  final GlobalKey<NavigatorState> eventsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'events_tab_navigator');
  final GlobalKey<NavigatorState> pointsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'points_tab_navigator');
  final GlobalKey<NavigatorState> profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profile_tab_navigator');

  GlobalKey<NavigatorState>? keyForTab(NavigationShellTab tab) {
    switch (tab) {
      case NavigationShellTab.home:
        return null;
      case NavigationShellTab.events:
        return eventsNavigatorKey;
      case NavigationShellTab.points:
        return pointsNavigatorKey;
      case NavigationShellTab.profile:
        return profileNavigatorKey;
    }
  }

  NavigatorState? navigatorForTab(NavigationShellTab tab) {
    return keyForTab(tab)?.currentState;
  }

  bool canPopInTab(NavigationShellTab tab) {
    final navigator = navigatorForTab(tab);
    if (navigator == null || !navigator.mounted) {
      return false;
    }
    return navigator.canPop();
  }

  void popInTab(NavigationShellTab tab) {
    final navigator = navigatorForTab(tab);
    if (navigator == null || !navigator.mounted || !navigator.canPop()) {
      return;
    }
    navigator.pop();
  }

  bool canPopToRootInTab(NavigationShellTab tab) {
    return canPopInTab(tab);
  }

  void popToRootInTab(NavigationShellTab tab) {
    final navigator = navigatorForTab(tab);
    if (navigator == null || !navigator.mounted || !navigator.canPop()) {
      return;
    }
    navigator.popUntil((route) => route.isFirst);
  }

  Future<T?> pushNamedInTab<T extends Object?>(
    NavigationShellTab tab,
    String routeName, {
    Object? arguments,
  }) {
    final navigator = navigatorForTab(tab);
    if (navigator == null || !navigator.mounted) {
      return Future<T?>.value(null);
    }
    return navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  bool handlesRouteInTab(NavigationShellTab tab, String routeName) {
    switch (tab) {
      case NavigationShellTab.home:
        return false;
      case NavigationShellTab.events:
        return routeName == AppRoutes.eventDetail;
      case NavigationShellTab.points:
        return routeName == AppRoutes.pointsHistory;
      case NavigationShellTab.profile:
        return routeName == AppRoutes.profileEdit ||
            routeName == AppRoutes.profileChangePassword;
    }
  }
}
