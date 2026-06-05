class NotificationPayloadLogSanitizer {
  const NotificationPayloadLogSanitizer._();

  static const int _maxLoggedKeys = 8;
  static const int _maxActionUrlLength = 80;
  static const Set<String> _sensitiveKeys = <String>{
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'password',
    'jwt',
    'email',
    'phone',
    'userId',
    'user_id',
    'code',
    'student_code',
  };

  static String summarize(Map<String, dynamic>? payload) {
    if (payload == null) {
      return 'payload=null';
    }
    if (payload.isEmpty) {
      return 'payload=empty';
    }

    final entries = payload.entries.take(_maxLoggedKeys);
    final preview = entries
        .map((entry) {
          final key = entry.key.trim();
          if (_isSensitiveKey(key)) {
            return '$key=<redacted>';
          }
          return key;
        })
        .join(', ');

    final hasMore = payload.length > _maxLoggedKeys;
    final suffix = hasMore ? ', ...' : '';
    return 'payloadKeys=${payload.length} {$preview$suffix}';
  }

  static String sanitizeActionUrl(String? actionUrl) {
    if (actionUrl == null || actionUrl.trim().isEmpty) {
      return '-';
    }

    final uri = Uri.tryParse(actionUrl);
    if (uri == null) {
      return _truncate(_normalizePath(actionUrl));
    }

    final normalizedPath = _normalizePath(uri.path);
    if (uri.hasScheme && uri.hasAuthority) {
      return _truncate('${uri.scheme}://${uri.host}$normalizedPath');
    }
    return _truncate(normalizedPath);
  }

  static bool _isSensitiveKey(String key) {
    if (_sensitiveKeys.contains(key)) {
      return true;
    }
    final normalized = key.toLowerCase();
    return normalized.contains('token') ||
        normalized.contains('password') ||
        normalized.contains('authorization');
  }

  static String _normalizePath(String rawPath) {
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

  static String _truncate(String input) {
    if (input.length <= _maxActionUrlLength) {
      return input;
    }
    return '${input.substring(0, _maxActionUrlLength)}...';
  }
}

