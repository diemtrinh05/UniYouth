import 'notification_observability_logger.dart';

class NotificationNavigationTarget {
  const NotificationNavigationTarget({required this.routeName, this.arguments});

  final String routeName;
  final Object? arguments;
}

class NotificationNavigationHandler {
  const NotificationNavigationHandler({
    this.notificationsRoute = '/notifications',
    this.eventDetailRoute = '/events/detail',
    this.supportChatRoute = '/support-chat',
    this.supportChatDetailRoute = '/support-chat/detail',
    this.enableDebugLogs = true,
    this.observabilityLogger = const NotificationObservabilityLogger(),
  });

  final String notificationsRoute;
  final String eventDetailRoute;
  final String supportChatRoute;
  final String supportChatDetailRoute;
  final bool enableDebugLogs;
  final NotificationObservabilityLogger observabilityLogger;

  NotificationNavigationTarget resolveTarget(Map<String, dynamic>? payload) {
    final supportConversationId = _resolveSupportConversationId(payload);
    if (supportConversationId != null) {
      final target = NotificationNavigationTarget(
        routeName: supportChatDetailRoute,
        arguments: supportConversationId,
      );
      _logResolution(
        payload: payload,
        target: target,
        reason: 'resolved_by_support_conversation_id',
      );
      return target;
    }

    final eventId = _resolveEventId(payload);
    if (eventId != null) {
      final target = NotificationNavigationTarget(
        routeName: eventDetailRoute,
        arguments: eventId,
      );
      _logResolution(
        payload: payload,
        target: target,
        reason: 'resolved_by_event_id',
      );
      return target;
    }

    final actionUrl = _extractActionUrl(payload);
    if (actionUrl != null) {
      final routeFromActionUrl = _resolveRouteFromActionUrl(actionUrl);
      if (routeFromActionUrl != null &&
          _isAllowedInternalRoute(routeFromActionUrl)) {
        final target = NotificationNavigationTarget(
          routeName: routeFromActionUrl,
        );
        _logResolution(
          payload: payload,
          target: target,
          reason: 'resolved_by_action_url',
          actionUrl: actionUrl,
        );
        return target;
      }
    }

    final fallbackTarget = NotificationNavigationTarget(
      routeName: notificationsRoute,
    );
    _logResolution(
      payload: payload,
      target: fallbackTarget,
      reason: 'fallback_notifications_route',
      actionUrl: actionUrl,
    );
    return fallbackTarget;
  }

  int? _resolveEventId(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    for (final key in const <String>[
      'eventId',
      'eventID',
      'event_id',
      'event',
    ]) {
      final parsed = _parsePositiveInt(payload[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    final actionUrl = _extractActionUrl(payload);
    if (actionUrl == null) {
      return null;
    }
    return _extractEventIdFromActionUrl(actionUrl);
  }

  String? _extractActionUrl(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    for (final key in const <String>[
      'actionUrl',
      'actionURL',
      'action_url',
      'deepLink',
      'deeplink',
      'link',
      'url',
    ]) {
      final rawValue = payload[key];
      if (rawValue == null) {
        continue;
      }

      final value = rawValue.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String? _resolveRouteFromActionUrl(String actionUrl) {
    final uri = Uri.tryParse(actionUrl);
    final path = uri == null
        ? _normalizePath(actionUrl)
        : _extractPathFromUri(uri);

    if (uri != null) {
      final hasUnsupportedScheme =
          uri.hasScheme &&
          uri.scheme != 'http' &&
          uri.scheme != 'https' &&
          uri.scheme != 'uniyouth';
      if (hasUnsupportedScheme) {
        return null;
      }
    }

    if (_isAllowedNotificationsPath(path)) {
      return notificationsRoute;
    }

    if (_isAllowedSupportChatPath(path)) {
      return supportChatRoute;
    }

    return null;
  }

  bool _isAllowedNotificationsPath(String path) {
    final normalizedNotificationsRoute = _normalizePath(notificationsRoute);
    if (path == normalizedNotificationsRoute) {
      return true;
    }

    if (path == '/notification' || path == '/notifications') {
      return true;
    }

    return false;
  }

  bool _isAllowedSupportChatPath(String path) {
    final normalizedSupportChatRoute = _normalizePath(supportChatRoute);
    final normalizedSupportChatDetailRoute = _normalizePath(
      supportChatDetailRoute,
    );
    if (path == normalizedSupportChatRoute ||
        path == normalizedSupportChatDetailRoute) {
      return true;
    }
    if (path == '/support-chat' || path == '/support') {
      return true;
    }
    if (RegExp(r'^/support-chat/[0-9]+$').hasMatch(path)) {
      return true;
    }
    return false;
  }

  bool _isAllowedEventPath(String path) {
    final normalizedEventDetailRoute = _normalizePath(eventDetailRoute);
    if (path == normalizedEventDetailRoute) {
      return true;
    }
    if (path == '/event/detail' || path == '/events/detail') {
      return true;
    }
    if (RegExp(r'^/events?/[0-9]+$').hasMatch(path)) {
      return true;
    }
    return false;
  }

  bool _isAllowedInternalRoute(String routeName) {
    return routeName == notificationsRoute ||
        routeName == eventDetailRoute ||
        routeName == supportChatRoute ||
        routeName == supportChatDetailRoute;
  }

  String _normalizePath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      return '/';
    }

    final withLeadingSlash = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    if (withLeadingSlash.length > 1 && withLeadingSlash.endsWith('/')) {
      return withLeadingSlash.substring(0, withLeadingSlash.length - 1);
    }

    return withLeadingSlash;
  }

  int? _extractEventIdFromActionUrl(String actionUrl) {
    final uri = Uri.tryParse(actionUrl);
    if (uri != null) {
      final path = _extractPathFromUri(uri);
      if (!_isAllowedEventPath(path)) {
        return null;
      }

      final queryEventId =
          _parsePositiveInt(uri.queryParameters['eventId']) ??
          _parsePositiveInt(uri.queryParameters['eventID']) ??
          _parsePositiveInt(uri.queryParameters['event_id']) ??
          _parsePositiveInt(uri.queryParameters['id']);
      if (queryEventId != null) {
        return queryEventId;
      }

      final segments = path
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      for (var i = 0; i < segments.length; i++) {
        final current = segments[i].toLowerCase();
        if ((current == 'event' || current == 'events') &&
            i + 1 < segments.length) {
          final parsed = _parsePositiveInt(segments[i + 1]);
          if (parsed != null) {
            return parsed;
          }
        }
      }
    }

    final normalizedPath = _normalizePath(actionUrl);
    if (!_isAllowedEventPath(normalizedPath)) {
      return null;
    }

    for (final pattern in <RegExp>[
      RegExp(r'event(?:Id|ID|_id)=([0-9]+)'),
      RegExp(r'/events?/([0-9]+)'),
    ]) {
      final match = pattern.firstMatch(actionUrl);
      if (match == null) {
        continue;
      }

      final parsed = _parsePositiveInt(match.group(1));
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  int? _resolveSupportConversationId(Map<String, dynamic>? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    for (final key in const <String>[
      'conversationId',
      'conversationID',
      'conversation_id',
      'supportConversationId',
      'supportConversationID',
    ]) {
      final parsed = _parsePositiveInt(payload[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    final actionUrl = _extractActionUrl(payload);
    if (actionUrl == null) {
      return null;
    }
    return _extractSupportConversationIdFromActionUrl(actionUrl);
  }

  int? _extractSupportConversationIdFromActionUrl(String actionUrl) {
    final uri = Uri.tryParse(actionUrl);
    if (uri != null) {
      final path = _extractPathFromUri(uri);
      if (!_isAllowedSupportChatPath(path)) {
        return null;
      }

      final queryConversationId =
          _parsePositiveInt(uri.queryParameters['conversationId']) ??
          _parsePositiveInt(uri.queryParameters['conversationID']) ??
          _parsePositiveInt(uri.queryParameters['conversation_id']) ??
          _parsePositiveInt(uri.queryParameters['id']);
      if (queryConversationId != null) {
        return queryConversationId;
      }

      final segments = path
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      if (segments.length >= 2 && segments.first == 'support-chat') {
        return _parsePositiveInt(segments[1]);
      }
    }

    final normalizedPath = _normalizePath(actionUrl);
    if (!_isAllowedSupportChatPath(normalizedPath)) {
      return null;
    }

    for (final pattern in <RegExp>[
      RegExp(r'conversation(?:Id|ID|_id)=([0-9]+)'),
      RegExp(r'/support-chat/([0-9]+)'),
    ]) {
      final match = pattern.firstMatch(actionUrl);
      if (match == null) {
        continue;
      }

      final parsed = _parsePositiveInt(match.group(1));
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  String _extractPathFromUri(Uri uri) {
    if (uri.scheme == 'uniyouth') {
      final hostSegment = uri.host.trim();
      final rawPath = uri.path.trim();
      final combinedPath = [
        if (hostSegment.isNotEmpty) hostSegment,
        if (rawPath.isNotEmpty)
          rawPath.startsWith('/') ? rawPath.substring(1) : rawPath,
      ].where((segment) => segment.isNotEmpty).join('/');

      return _normalizePath(combinedPath);
    }

    return _normalizePath(uri.path);
  }

  int? _parsePositiveInt(Object? raw) {
    if (raw == null) {
      return null;
    }

    final parsed = int.tryParse(raw.toString().trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  void _logResolution({
    required Map<String, dynamic>? payload,
    required NotificationNavigationTarget target,
    required String reason,
    String? actionUrl,
  }) {
    if (!enableDebugLogs) {
      return;
    }

    observabilityLogger.logNavigationDecision(
      routeName: target.routeName,
      hasArguments: target.arguments != null,
      reason: reason,
      actionUrl: actionUrl,
      payload: payload,
    );
  }
}
