import 'dart:async';

import '../../domain/usecases/device_token/register_device_token_usecase.dart';
import '../../domain/usecases/device_token/unregister_device_token_usecase.dart';
import 'device_push_platform_resolver.dart';
import 'firebase_service.dart';
import 'notification_observability_logger.dart';

typedef DeviceTokenSyncErrorHandler =
    void Function(Object error, StackTrace stackTrace);

class DeviceTokenSyncService {
  DeviceTokenSyncService({
    required FirebaseService firebaseService,
    required RegisterDeviceTokenUseCase registerDeviceTokenUseCase,
    required UnregisterDeviceTokenUseCase unregisterDeviceTokenUseCase,
    required DevicePushPlatformResolver platformResolver,
    NotificationObservabilityLogger observabilityLogger =
        const NotificationObservabilityLogger(),
    DeviceTokenSyncErrorHandler? onError,
  })  : _firebaseService = firebaseService,
        _registerDeviceTokenUseCase = registerDeviceTokenUseCase,
        _unregisterDeviceTokenUseCase = unregisterDeviceTokenUseCase,
        _platformResolver = platformResolver,
        _observabilityLogger = observabilityLogger,
        _onError = onError;

  final FirebaseService _firebaseService;
  final RegisterDeviceTokenUseCase _registerDeviceTokenUseCase;
  final UnregisterDeviceTokenUseCase _unregisterDeviceTokenUseCase;
  final DevicePushPlatformResolver _platformResolver;
  final NotificationObservabilityLogger _observabilityLogger;
  final DeviceTokenSyncErrorHandler? _onError;

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastRegisteredTokenKey;
  Future<void>? _syncInFlight;

  Future<void> syncCurrentTokenIfNeeded() {
    final inFlight = _syncInFlight;
    if (inFlight != null) {
      _observabilityLogger.logTokenLifecycle(
        action: 'token_sync',
        status: 'reuse_inflight',
      );
      return inFlight;
    }

    _observabilityLogger.logTokenLifecycle(
      action: 'token_sync',
      status: 'started',
    );
    final pending = _syncCurrentTokenIfNeededInternal().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _observabilityLogger.logTokenLifecycle(
        action: 'token_sync',
        status: 'failed',
        error: error,
      );
      throw error;
    });
    _syncInFlight = pending;
    return pending.whenComplete(() {
      _syncInFlight = null;
      _observabilityLogger.logTokenLifecycle(
        action: 'token_sync',
        status: 'completed',
      );
    });
  }

  void startTokenRefreshSync() {
    if (_tokenRefreshSubscription != null) {
      _observabilityLogger.logTokenLifecycle(
        action: 'token_refresh_listener',
        status: 'already_started',
      );
      return;
    }

    _observabilityLogger.logTokenLifecycle(
      action: 'token_refresh_listener',
      status: 'started',
    );
    _tokenRefreshSubscription = _firebaseService.onTokenRefresh.listen((
      _,
    ) async {
      try {
        await syncCurrentTokenIfNeeded();
      } catch (error, stackTrace) {
        _observabilityLogger.logTokenLifecycle(
          action: 'token_refresh_listener',
          status: 'sync_failed',
          error: error,
        );
        _onError?.call(error, stackTrace);
      }
    });
  }

  Future<void> unregisterCurrentToken() async {
    _observabilityLogger.logTokenLifecycle(
      action: 'token_unregister',
      status: 'started',
    );
    await _unregisterDeviceTokenUseCase();
    _lastRegisteredTokenKey = null;
    _observabilityLogger.logTokenLifecycle(
      action: 'token_unregister',
      status: 'completed',
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _observabilityLogger.logTokenLifecycle(
      action: 'token_refresh_listener',
      status: 'disposed',
    );
  }

  Future<void> _syncCurrentTokenIfNeededInternal() async {
    final token = await _firebaseService.getToken();
    final normalizedToken = token?.trim();
    if (normalizedToken == null || normalizedToken.isEmpty) {
      _observabilityLogger.logTokenLifecycle(
        action: 'token_sync',
        status: 'skip_empty_token',
        hasToken: false,
      );
      return;
    }

    final platform = _platformResolver.resolve();
    final tokenKey = '${platform.name}::$normalizedToken';
    if (_lastRegisteredTokenKey == tokenKey) {
      _observabilityLogger.logTokenLifecycle(
        action: 'token_sync',
        status: 'skip_unchanged_token',
        platform: platform.name,
        hasToken: true,
      );
      return;
    }

    await _registerDeviceTokenUseCase();
    _lastRegisteredTokenKey = tokenKey;
    _observabilityLogger.logTokenLifecycle(
      action: 'token_sync',
      status: 'registered',
      platform: platform.name,
      hasToken: true,
    );
  }
}
