import 'package:flutter/material.dart';

class AppRouteStackObserver extends NavigatorObserver {
  final List<String?> _routeNames = <String?>[];

  bool containsRoute(String routeName) {
    return _routeNames.contains(routeName);
  }

  String? get currentRouteName {
    if (_routeNames.isEmpty) {
      return null;
    }
    return _routeNames.last;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routeNames.add(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_routeNames.isNotEmpty) {
      _routeNames.removeLast();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routeNames.remove(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      _routeNames.remove(oldRoute.settings.name);
    }
    if (newRoute != null) {
      _routeNames.add(newRoute.settings.name);
    }
  }
}
