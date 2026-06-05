import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/app_dio.dart';
import '../../core/notifications/device_token_sync_service.dart';
import '../../core/notifications/firebase_service.dart';
import '../../services/config/api_config_service.dart';
import 'providers/app_provider_graph.dart';
import 'router/app_router.dart';
import 'router/app_route_stack_observer.dart';
import 'router/app_routes.dart';
import '../navigation/state/navigation_shell_provider.dart';
import '../navigation/tab_navigation_coordinator.dart';

class UniYouthApp extends StatefulWidget {
  const UniYouthApp({super.key, required this.apiConfigService});

  final ApiConfigService apiConfigService;

  @override
  State<UniYouthApp> createState() => _UniYouthAppState();
}

class _UniYouthAppState extends State<UniYouthApp> {
  late final _UniYouthAppView _appView;

  @override
  void initState() {
    super.initState();
    _appView = _UniYouthAppView(apiConfigService: widget.apiConfigService);
  }

  @override
  void dispose() {
    _appView.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _appView.build(context);
}

class _UniYouthAppView {
  _UniYouthAppView({required ApiConfigService apiConfigService})
    : _apiConfigService = apiConfigService {
    _providerContainer = ProviderContainer(
      overrides: [
        apiConfigServiceProvider.overrideWithValue(_apiConfigService),
        clearLocalSessionCallbackProvider.overrideWithValue(_clearLocalSession),
        redirectToLoginCallbackProvider.overrideWithValue(_redirectToLogin),
      ],
    );

    _logResolvedApiConfig();
    _apiConfigService.addListener(_handleApiConfigChanged);

    _notificationLifecycleSyncController = _providerContainer.read(
      notificationLifecycleSyncControllerProvider,
    );
    _firebaseService = _providerContainer.read(firebaseServiceProvider);
    _deviceTokenSyncService = _providerContainer.read(
      deviceTokenSyncServiceProvider,
    );

    _appLifecycleObserver = _AppLifecycleNotificationObserver(
      onResumed: _emitNotificationLifecycleSync,
    );
    WidgetsBinding.instance.addObserver(_appLifecycleObserver);

    _onAuthenticatedTokenSync = () async {
      _shouldPromptNotificationPermissionSettings = false;
      try {
        await _firebaseService.initialize();
      } catch (_) {
        return false;
      }
      try {
        final permissionStatus = await _firebaseService.requestPermission();
        if (permissionStatus == PushPermissionStatus.denied) {
          _shouldPromptNotificationPermissionSettings = true;
        }
      } catch (_) {}
      _deviceTokenSyncService.startTokenRefreshSync();
      try {
        await _deviceTokenSyncService.syncCurrentTokenIfNeeded();
      } catch (_) {}
      try {
        final initialMessage = await _firebaseService.getInitialMessage();
        if (initialMessage != null) {
          await navigateFromNotificationPayload(initialMessage.data);
          _emitNotificationLifecycleSync();
          return true;
        }
      } catch (_) {}
      return false;
    };

    _onLogout = () async {
      try {
        await _deviceTokenSyncService.unregisterCurrentToken();
      } catch (_) {}
      try {
        await _providerContainer
            .read(authSessionLifecycleRepositoryProvider)
            .revokeCurrentSession();
      } catch (_) {}
      try {
        await _deviceTokenSyncService.dispose();
      } catch (_) {}

      await _clearLocalSession();
      _resetShellNavigationState();
      await _redirectToLogin();
    };

    _appRouter = AppRouter(
      authBindings: _providerContainer.read(authNavigationBindingsProvider),
      eventsBindings: _providerContainer.read(eventsNavigationBindingsProvider),
      attendanceBindings: _providerContainer.read(
        attendanceNavigationBindingsProvider,
      ),
      pointsBindings: _providerContainer.read(pointsNavigationBindingsProvider),
      profileBindings: _providerContainer.read(
        profileNavigationBindingsProvider,
      ),
      onAuthenticatedTokenSync: _onAuthenticatedTokenSync,
      consumeNotificationPermissionDeniedHint:
          _consumeNotificationPermissionDeniedHint,
      notificationNavigationHandler: _providerContainer.read(
        notificationNavigationHandlerProvider,
      ),
      onLogout: _onLogout,
      routeStackObserver: _routeStackObserver,
      tabNavigationCoordinator: _tabNavigationCoordinator,
    );

    _onMessageSubscription = _firebaseService.onMessage.listen((_) {
      _emitNotificationLifecycleSync();
    });

    _onMessageOpenedAppSubscription = _firebaseService.onMessageOpenedApp
        .listen((payload) {
          unawaited(_handleNotificationOpenedApp(payload.data));
        });
  }

  static const bool _isProduct = bool.fromEnvironment('dart.vm.product');

  final ApiConfigService _apiConfigService;
  late final ProviderContainer _providerContainer;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AppRouteStackObserver _routeStackObserver = AppRouteStackObserver();
  final AppShellTabNavigationCoordinator _tabNavigationCoordinator =
      AppShellTabNavigationCoordinator();
  final _PendingNotificationNavigationQueue
  _pendingNotificationNavigationQueue = _PendingNotificationNavigationQueue();

  late final StreamController<void> _notificationLifecycleSyncController;
  late final FirebaseService _firebaseService;
  late final DeviceTokenSyncService _deviceTokenSyncService;
  late final WidgetsBindingObserver _appLifecycleObserver;
  late final Future<bool> Function() _onAuthenticatedTokenSync;
  late final Future<void> Function() _onLogout;
  late final AppRouter _appRouter;

  StreamSubscription<dynamic>? _onMessageSubscription;
  StreamSubscription<dynamic>? _onMessageOpenedAppSubscription;
  bool _isDisposed = false;
  bool _shouldPromptNotificationPermissionSettings = false;

  void _logResolvedApiConfig() {
    final appEnv = _apiConfigService.normalizedAppEnv;
    final baseUrl = _apiConfigService.resolveBaseUrl();
    if (!_isProduct) {
      developer.log('APP_ENV=$appEnv API_BASE_URL=$baseUrl', name: 'config');
    }
  }

  void _handleApiConfigChanged() {
    final baseUrl = _apiConfigService.resolveBaseUrl();
    AppDio.updateBaseUrl(baseUrl);
    _providerContainer.invalidate(apiBaseUrlProvider);
    _providerContainer.invalidate(dioProvider);
    _logResolvedApiConfig();
  }

  void _emitNotificationLifecycleSync() {
    if (_notificationLifecycleSyncController.isClosed) {
      return;
    }
    _notificationLifecycleSyncController.add(null);
  }

  bool _consumeNotificationPermissionDeniedHint() {
    final shouldShow = _shouldPromptNotificationPermissionSettings;
    _shouldPromptNotificationPermissionSettings = false;
    return shouldShow;
  }

  Future<void> _clearLocalSession() async {
    await _providerContainer.read(authSessionRepositoryProvider).clearSession();
    _providerContainer.read(authTokenProvider).setAccessToken(null);
  }

  Future<void> _redirectToLogin() async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    // Reset stack to avoid landing back on protected pages after 401.
    await navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  void _resetShellNavigationState() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      return;
    }

    try {
      final container = ProviderScope.containerOf(
        navigator.context,
        listen: false,
      );
      container.read(navigationShellNotifierProvider.notifier).reset();
    } catch (_) {}
  }

  Future<void> navigateFromNotificationPayload(
    Map<String, dynamic>? payload,
  ) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      _pendingNotificationNavigationQueue.enqueue(payload);
      _schedulePendingNotificationNavigationDrain();
      return;
    }

    await _appRouter.navigateFromNotificationPayload(
      navigator: navigator,
      payload: payload,
    );
  }

  void _schedulePendingNotificationNavigationDrain() {
    if (_pendingNotificationNavigationQueue.isDrainScheduled ||
        _pendingNotificationNavigationQueue.isDraining ||
        !_pendingNotificationNavigationQueue.hasItems) {
      return;
    }

    _pendingNotificationNavigationQueue.isDrainScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingNotificationNavigationQueue.isDrainScheduled = false;
      unawaited(_drainPendingNotificationNavigation());
    });
  }

  Future<void> _drainPendingNotificationNavigation() async {
    if (_pendingNotificationNavigationQueue.isDraining ||
        !_pendingNotificationNavigationQueue.hasItems) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      _schedulePendingNotificationNavigationDrain();
      return;
    }

    _pendingNotificationNavigationQueue.isDraining = true;
    try {
      final nextPayload = _pendingNotificationNavigationQueue.dequeue();
      await _appRouter.navigateFromNotificationPayload(
        navigator: navigator,
        payload: nextPayload,
      );
    } finally {
      _pendingNotificationNavigationQueue.isDraining = false;
    }

    if (_pendingNotificationNavigationQueue.hasItems) {
      _schedulePendingNotificationNavigationDrain();
    }
  }

  Future<void> _handleNotificationOpenedApp(
    Map<String, dynamic>? payload,
  ) async {
    await navigateFromNotificationPayload(payload);
    _emitNotificationLifecycleSync();
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _apiConfigService.removeListener(_handleApiConfigChanged);

    WidgetsBinding.instance.removeObserver(_appLifecycleObserver);

    final onMessageSubscription = _onMessageSubscription;
    _onMessageSubscription = null;
    if (onMessageSubscription != null) {
      unawaited(onMessageSubscription.cancel());
    }

    final onMessageOpenedAppSubscription = _onMessageOpenedAppSubscription;
    _onMessageOpenedAppSubscription = null;
    if (onMessageOpenedAppSubscription != null) {
      unawaited(onMessageOpenedAppSubscription.cancel());
    }

    _providerContainer.dispose();
  }

  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _providerContainer,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        navigatorObservers: <NavigatorObserver>[_routeStackObserver],
        title: 'UniYouth',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        initialRoute: AppRoutes.splash,

        onGenerateRoute: _appRouter.onGenerateRoute,
      ),
    );
  }
}

class _AppLifecycleNotificationObserver with WidgetsBindingObserver {
  _AppLifecycleNotificationObserver({required void Function() onResumed})
    : _onResumed = onResumed;

  final void Function() _onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    _onResumed();
  }
}

class _PendingNotificationNavigationQueue {
  final Queue<Map<String, dynamic>?> _items = Queue<Map<String, dynamic>?>();

  bool isDrainScheduled = false;
  bool isDraining = false;

  bool get hasItems => _items.isNotEmpty;

  void enqueue(Map<String, dynamic>? payload) {
    _items.addLast(payload);
  }

  Map<String, dynamic>? dequeue() {
    return _items.removeFirst();
  }
}
