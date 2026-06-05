import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/device_push_platform_resolver.dart';
import '../../../core/notifications/device_push_token_provider.dart';
import '../../../core/notifications/device_token_sync_service.dart';
import '../../../core/notifications/firebase_service.dart';
import '../../../core/notifications/notification_navigation_handler.dart';
import '../../../data/repositories/device_token/device_token_repository_impl.dart';
import '../../../data/repositories/notifications/notifications_repository_impl.dart';
import '../../../domain/usecases/device_token/register_device_token_usecase.dart';
import '../../../domain/usecases/device_token/unregister_device_token_usecase.dart';
import '../../../domain/usecases/notifications/get_notifications_usecase.dart';
import '../../../domain/usecases/notifications/get_unread_count_usecase.dart';
import '../../../domain/usecases/notifications/mark_all_as_read_usecase.dart';
import '../../../domain/usecases/notifications/mark_as_read_usecase.dart';
import '../router/app_routes.dart';
import 'app_foundation_providers.dart';

final devicePushPlatformResolverProvider = Provider<DevicePushPlatformResolver>(
  (ref) => DevicePushPlatformResolver(),
);

final devicePushTokenProvider = Provider<DevicePushTokenProvider>(
  (ref) => FirebaseDevicePushTokenProvider(),
);

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepositoryImpl>(
  (ref) => DeviceTokenRepositoryImpl(
    remoteDataSource: ref.watch(deviceTokenRemoteDataSourceProvider),
    platformResolver: ref.watch(devicePushPlatformResolverProvider),
    tokenProvider: ref.watch(devicePushTokenProvider),
  ),
);

final notificationsRepositoryProvider = Provider<NotificationsRepositoryImpl>(
  (ref) => NotificationsRepositoryImpl(
    remoteDataSource: ref.watch(notificationsRemoteDataSourceProvider),
  ),
);

final registerDeviceTokenUseCaseProvider = Provider<RegisterDeviceTokenUseCase>(
  (ref) => RegisterDeviceTokenUseCase(
    repository: ref.watch(deviceTokenRepositoryProvider),
  ),
);

final unregisterDeviceTokenUseCaseProvider =
    Provider<UnregisterDeviceTokenUseCase>(
      (ref) => UnregisterDeviceTokenUseCase(
        repository: ref.watch(deviceTokenRepositoryProvider),
      ),
    );

final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>(
  (ref) => GetNotificationsUseCase(
    repository: ref.watch(notificationsRepositoryProvider),
  ),
);

final getUnreadCountUseCaseProvider = Provider<GetUnreadCountUseCase>(
  (ref) => GetUnreadCountUseCase(
    repository: ref.watch(notificationsRepositoryProvider),
  ),
);

final markAsReadUseCaseProvider = Provider<MarkAsReadUseCase>(
  (ref) =>
      MarkAsReadUseCase(repository: ref.watch(notificationsRepositoryProvider)),
);

final markAllAsReadUseCaseProvider = Provider<MarkAllAsReadUseCase>(
  (ref) => MarkAllAsReadUseCase(
    repository: ref.watch(notificationsRepositoryProvider),
  ),
);

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final service = FirebaseMessagingService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final deviceTokenSyncServiceProvider = Provider<DeviceTokenSyncService>((ref) {
  final service = DeviceTokenSyncService(
    firebaseService: ref.watch(firebaseServiceProvider),
    registerDeviceTokenUseCase: ref.watch(registerDeviceTokenUseCaseProvider),
    unregisterDeviceTokenUseCase: ref.watch(
      unregisterDeviceTokenUseCaseProvider,
    ),
    platformResolver: ref.watch(devicePushPlatformResolverProvider),
  );
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final notificationNavigationHandlerProvider =
    Provider<NotificationNavigationHandler>(
      (ref) => const NotificationNavigationHandler(
        notificationsRoute: AppRoutes.notifications,
        eventDetailRoute: AppRoutes.eventDetail,
      ),
    );

final notificationLifecycleSyncControllerProvider =
    Provider<StreamController<void>>((ref) {
      final controller = StreamController<void>.broadcast();
      ref.onDispose(() {
        unawaited(controller.close());
      });
      return controller;
    });

final notificationLifecycleSyncStreamProvider = Provider<Stream<void>>(
  (ref) => ref.watch(notificationLifecycleSyncControllerProvider).stream,
);

class NotificationUnreadCountController extends Notifier<int> {
  @override
  int build() => 0;

  void setUnreadCount(int unreadCount) {
    final normalizedUnreadCount = unreadCount < 0 ? 0 : unreadCount;
    if (state == normalizedUnreadCount) {
      return;
    }
    state = normalizedUnreadCount;
  }
}

final notificationUnreadCountProvider =
    NotifierProvider<NotificationUnreadCountController, int>(
      NotificationUnreadCountController.new,
    );
