class UnauthorizedSessionHandler {
  UnauthorizedSessionHandler({
    required Future<void> Function() clearLocalSession,
    required Future<void> Function() redirectToLogin,
    Duration dedupeWindow = const Duration(seconds: 3),
  }) : _clearLocalSession = clearLocalSession,
       _redirectToLogin = redirectToLogin,
       _dedupeWindow = dedupeWindow;

  final Future<void> Function() _clearLocalSession;
  final Future<void> Function() _redirectToLogin;
  final Duration _dedupeWindow;

  bool _isHandling = false;
  DateTime? _lastHandledAt;

  Future<void> handleUnauthorized() async {
    final now = DateTime.now();
    if (_isHandling) {
      return;
    }

    // Drop duplicate 401 bursts from concurrent requests.
    if (_lastHandledAt != null &&
        now.difference(_lastHandledAt!) <= _dedupeWindow) {
      return;
    }

    _isHandling = true;
    _lastHandledAt = now;
    try {
      await _clearLocalSession();
      await _redirectToLogin();
    } finally {
      _isHandling = false;
    }
  }
}
