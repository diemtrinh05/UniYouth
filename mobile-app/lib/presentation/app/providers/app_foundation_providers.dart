import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/unauthorized_session_handler.dart';
import '../../../core/network/app_dio.dart';
import '../../../core/network/auth_token_provider.dart';
import '../../../core/network/idempotency_key_provider.dart';
import '../../../core/storage/secure_key_value_storage.dart';
import '../../../services/config/api_config_service.dart';
import '../../../services/network/lan_server_discovery_service.dart';
import '../../../services/realtime/support_chat_realtime_service.dart';
import '../../../data/datasources/remote/auth_remote_datasource.dart';
import '../../../data/datasources/remote/device_token_remote_datasource.dart';
import '../../../data/datasources/remote/event_type_remote_datasource.dart';
import '../../../data/datasources/remote/events_remote_datasource.dart';
import '../../../data/datasources/remote/notifications_remote_datasource.dart';
import '../../../data/datasources/remote/points_remote_datasource.dart';
import '../../../data/datasources/remote/support_chat_remote_datasource.dart';
import '../../../data/datasources/remote/users_remote_datasource.dart';
import '../../../data/repositories/auth/auth_session_lifecycle_repository.dart';
import '../../../data/repositories/auth/auth_session_repository.dart';
import '../../../data/repositories/auth/secure_auth_session_repository.dart';

final apiConfigServiceProvider = Provider<ApiConfigService>(
  (ref) =>
      throw UnimplementedError('apiConfigServiceProvider must be overridden.'),
);

final appEnvProvider = Provider<String>(
  (ref) => ref.watch(apiConfigServiceProvider).normalizedAppEnv,
);

final apiBaseUrlProvider = Provider<String>(
  (ref) => ref.watch(apiConfigServiceProvider).resolveBaseUrl(),
);

final lanServerDiscoveryServiceProvider = Provider<LanServerDiscoveryService>(
  (ref) => LanServerDiscoveryService(),
);

final clearLocalSessionCallbackProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => Future<void>.error(
        UnimplementedError(
          'clearLocalSessionCallbackProvider must be overridden.',
        ),
      ),
);

final redirectToLoginCallbackProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => Future<void>.error(
        UnimplementedError(
          'redirectToLoginCallbackProvider must be overridden.',
        ),
      ),
);

final secureStorageProvider = Provider<SecureKeyValueStorage>(
  (ref) => FlutterSecureKeyValueStorage(),
);

final authTokenProvider = Provider<InMemoryAuthTokenProvider>(
  (ref) => InMemoryAuthTokenProvider(),
);

final authSessionRepositoryProvider = Provider<AuthSessionRepository>(
  (ref) =>
      SecureAuthSessionRepository(storage: ref.watch(secureStorageProvider)),
);

final authLifecycleDioProvider = Provider<Dio>(
  (ref) => AppDio.createPlainInstance(baseUrl: ref.watch(apiBaseUrlProvider)),
);

final authLifecycleRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(dio: ref.watch(authLifecycleDioProvider)),
);

final unauthorizedSessionHandlerProvider = Provider<UnauthorizedSessionHandler>(
  (ref) => UnauthorizedSessionHandler(
    clearLocalSession: ref.watch(clearLocalSessionCallbackProvider),
    redirectToLogin: ref.watch(redirectToLoginCallbackProvider),
  ),
);

final authSessionLifecycleRepositoryProvider =
    Provider<AuthSessionLifecycleRepository>(
      (ref) => AuthSessionLifecycleRepository(
        authRemoteDataSource: ref.watch(authLifecycleRemoteDataSourceProvider),
        authSessionRepository: ref.watch(authSessionRepositoryProvider),
        tokenProvider: ref.watch(authTokenProvider),
      ),
    );

final dioProvider = Provider<Dio>(
  (ref) => AppDio.getSharedInstance(
    baseUrl: ref.watch(apiBaseUrlProvider),
    tokenProvider: ref.watch(authTokenProvider),
    tryRefreshToken: ref
        .watch(authSessionLifecycleRepositoryProvider)
        .tryRefreshSession,
    onUnauthorized: ref
        .watch(unauthorizedSessionHandlerProvider)
        .handleUnauthorized,
  ),
);

final usersRemoteDataSourceProvider = Provider<UsersRemoteDataSource>(
  (ref) => UsersRemoteDataSource(dio: ref.watch(dioProvider)),
);

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(dio: ref.watch(dioProvider)),
);

final deviceTokenRemoteDataSourceProvider =
    Provider<DeviceTokenRemoteDataSource>(
      (ref) => DeviceTokenRemoteDataSource(dio: ref.watch(dioProvider)),
    );

final eventTypeRemoteDataSourceProvider = Provider<EventTypeRemoteDataSource>(
  (ref) => EventTypeRemoteDataSource(dio: ref.watch(dioProvider)),
);

final eventsRemoteDataSourceProvider = Provider<EventsRemoteDataSource>(
  (ref) => EventsRemoteDataSource(dio: ref.watch(dioProvider)),
);

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
      (ref) => NotificationsRemoteDataSource(dio: ref.watch(dioProvider)),
    );

final pointsRemoteDataSourceProvider = Provider<PointsRemoteDataSource>(
  (ref) => PointsRemoteDataSource(dio: ref.watch(dioProvider)),
);

final supportChatRemoteDataSourceProvider =
    Provider<SupportChatRemoteDataSource>(
      (ref) => SupportChatRemoteDataSource(dio: ref.watch(dioProvider)),
    );

final supportChatRealtimeServiceProvider = Provider<SupportChatRealtimeService>(
  (ref) {
    final service = SupportChatRealtimeService(
      apiBaseUrl: ref.watch(apiBaseUrlProvider),
      authTokenProvider: ref.watch(authTokenProvider),
    );
    ref.onDispose(() {
      unawaited(service.dispose());
    });
    return service;
  },
);

final idempotencyKeyProviderProvider = Provider<IdempotencyKeyProvider>(
  (ref) => TimestampIdempotencyKeyProvider(),
);
