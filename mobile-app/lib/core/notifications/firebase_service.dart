import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_observability_logger.dart';

Future<void>? _firebaseCoreInitializationInFlight;

Future<void> ensureFirebaseCoreInitialized() {
  if (Firebase.apps.isNotEmpty) {
    return Future<void>.value();
  }

  final inFlight = _firebaseCoreInitializationInFlight;
  if (inFlight != null) {
    return inFlight;
  }

  final pending = Firebase.initializeApp().then((_) {});
  _firebaseCoreInitializationInFlight = pending;
  return pending.catchError((Object error, StackTrace stackTrace) {
    _firebaseCoreInitializationInFlight = null;
    throw error;
  });
}

enum PushPermissionStatus { authorized, provisional, denied, notDetermined }

class PushMessagePayload {
  const PushMessagePayload({
    required this.data,
    this.messageId,
    this.title,
    this.body,
    this.sentTime,
  });

  factory PushMessagePayload.fromRemoteMessage(RemoteMessage message) {
    return PushMessagePayload(
      messageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      sentTime: message.sentTime,
      data: Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(message.data),
      ),
    );
  }

  final String? messageId;
  final String? title;
  final String? body;
  final DateTime? sentTime;
  final Map<String, dynamic> data;
}

abstract class FirebaseService {
  Future<void> initialize();

  Future<PushPermissionStatus> getPermissionStatus();

  Future<PushPermissionStatus> requestPermission();

  Future<String?> getToken();

  Stream<PushMessagePayload> get onMessage;

  Stream<PushMessagePayload> get onMessageOpenedApp;

  Future<PushMessagePayload?> getInitialMessage();

  Stream<String> get onTokenRefresh;

  Future<void> dispose();
}

class FirebaseMessagingService implements FirebaseService {
  FirebaseMessagingService({
    FirebaseMessaging? messaging,
    NotificationObservabilityLogger observabilityLogger =
        const NotificationObservabilityLogger(),
  }) : _messagingOverride = messaging,
       _observabilityLogger = observabilityLogger;

  static const String _foregroundChannelId = 'uniyouth_foreground_channel';
  static const AndroidNotificationChannel _foregroundNotificationChannel =
      AndroidNotificationChannel(
        _foregroundChannelId,
        'Foreground Notifications',
        description: 'Shows notifications while the app is in foreground.',
        importance: Importance.high,
      );

  final FirebaseMessaging? _messagingOverride;
  final NotificationObservabilityLogger _observabilityLogger;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<PushMessagePayload> _onMessageController =
      StreamController<PushMessagePayload>.broadcast();
  final StreamController<PushMessagePayload> _onMessageOpenedAppController =
      StreamController<PushMessagePayload>.broadcast();
  final StreamController<String> _onTokenRefreshController =
      StreamController<String>.broadcast();

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  bool _localNotificationsInitialized = false;
  bool _initialized = false;
  bool _isDisposed = false;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  @override
  Stream<PushMessagePayload> get onMessage => _onMessageController.stream;

  @override
  Stream<PushMessagePayload> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;

  @override
  Stream<String> get onTokenRefresh => _onTokenRefreshController.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      _observabilityLogger.logTokenLifecycle(
        action: 'firebase_initialize',
        status: 'already_initialized',
      );
      return;
    }

    _observabilityLogger.logTokenLifecycle(
      action: 'firebase_initialize',
      status: 'started',
    );
    await ensureFirebaseCoreInitialized();
    await _initializeLocalNotifications();
    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _onMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
      _observabilityLogger.logPushReceipt(
        source: 'foreground',
        messageId: message.messageId,
        payload: message.data,
        hasVisualContent:
            _cleanText(message.notification?.title) != null ||
            _cleanText(message.notification?.body) != null,
      );
      _onMessageController.add(PushMessagePayload.fromRemoteMessage(message));
      unawaited(_showForegroundLocalNotification(message));
    });
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen((message) {
          _observabilityLogger.logPushReceipt(
            source: 'opened_app',
            messageId: message.messageId,
            payload: message.data,
            hasVisualContent:
                _cleanText(message.notification?.title) != null ||
                _cleanText(message.notification?.body) != null,
          );
          _onMessageOpenedAppController.add(
            PushMessagePayload.fromRemoteMessage(message),
          );
        });

    _onTokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      final normalized = token.trim();
      if (normalized.isEmpty) {
        _observabilityLogger.logTokenLifecycle(
          action: 'fcm_token_refresh',
          status: 'empty_token',
          hasToken: false,
        );
        return;
      }
      _observabilityLogger.logTokenLifecycle(
        action: 'fcm_token_refresh',
        status: 'received',
        hasToken: true,
      );
      _onTokenRefreshController.add(normalized);
    });

    _initialized = true;
    _observabilityLogger.logTokenLifecycle(
      action: 'firebase_initialize',
      status: 'completed',
    );
  }

  @override
  Future<PushPermissionStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<PushPermissionStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final status = _mapAuthorizationStatus(settings.authorizationStatus);
    _observabilityLogger.logTokenLifecycle(
      action: 'notification_permission_request',
      status: status.name,
    );
    return status;
  }

  @override
  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    if (token == null) {
      _observabilityLogger.logTokenLifecycle(
        action: 'fcm_get_token',
        status: 'null_token',
        hasToken: false,
      );
      return null;
    }
    final normalized = token.trim();
    if (normalized.isEmpty) {
      _observabilityLogger.logTokenLifecycle(
        action: 'fcm_get_token',
        status: 'empty_token',
        hasToken: false,
      );
      return null;
    }
    _observabilityLogger.logTokenLifecycle(
      action: 'fcm_get_token',
      status: 'success',
      hasToken: true,
    );
    return normalized;
  }

  @override
  Future<PushMessagePayload?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) {
      _observabilityLogger.logPushReceipt(
        source: 'initial_message',
        messageId: null,
        payload: null,
        hasVisualContent: false,
      );
      return null;
    }
    _observabilityLogger.logPushReceipt(
      source: 'initial_message',
      messageId: message.messageId,
      payload: message.data,
      hasVisualContent:
          _cleanText(message.notification?.title) != null ||
          _cleanText(message.notification?.body) != null,
    );
    return PushMessagePayload.fromRemoteMessage(message);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _observabilityLogger.logTokenLifecycle(
      action: 'firebase_dispose',
      status: 'started',
    );
    await _onMessageSubscription?.cancel();
    _onMessageSubscription = null;
    await _onMessageOpenedAppSubscription?.cancel();
    _onMessageOpenedAppSubscription = null;
    await _onTokenRefreshSubscription?.cancel();
    _onTokenRefreshSubscription = null;

    if (!_onMessageController.isClosed) {
      await _onMessageController.close();
    }
    if (!_onMessageOpenedAppController.isClosed) {
      await _onMessageOpenedAppController.close();
    }
    if (!_onTokenRefreshController.isClosed) {
      await _onTokenRefreshController.close();
    }

    _observabilityLogger.logTokenLifecycle(
      action: 'firebase_dispose',
      status: 'completed',
    );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _localNotificationsPlugin.initialize(settings: settings);
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_foregroundNotificationChannel);

    _localNotificationsInitialized = true;
  }

  Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
    if (!_localNotificationsInitialized) {
      return;
    }

    final title =
        _cleanText(message.notification?.title) ??
        _extractDataText(message.data, const <String>['title']);
    final body =
        _cleanText(message.notification?.body) ??
        _extractDataText(message.data, const <String>['body', 'content']);

    if (title == null && body == null) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _foregroundChannelId,
        'Foreground Notifications',
        channelDescription:
            'Shows notifications while the app is in foreground.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final id = _buildLocalNotificationId(message);
    await _localNotificationsPlugin.show(
      id: id,
      title: title ?? '',
      body: body ?? '',
      notificationDetails: details,
    );
  }

  String? _extractDataText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final rawValue = data[key];
      final normalized = _cleanText(rawValue?.toString());
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  String? _cleanText(String? text) {
    final normalized = text?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  int _buildLocalNotificationId(RemoteMessage message) {
    final fromMessageId = message.messageId;
    if (fromMessageId != null && fromMessageId.isNotEmpty) {
      return fromMessageId.hashCode & 0x7fffffff;
    }
    return DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
  }

  PushPermissionStatus _mapAuthorizationStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return PushPermissionStatus.authorized;
      case AuthorizationStatus.provisional:
        return PushPermissionStatus.provisional;
      case AuthorizationStatus.denied:
        return PushPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return PushPermissionStatus.notDetermined;
    }
  }
}
