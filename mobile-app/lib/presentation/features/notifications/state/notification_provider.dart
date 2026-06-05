import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../app/providers/app_provider_graph.dart';
import 'notification_notifier.dart';
import 'notification_state.dart';

class NotificationUnreadSyncController {
  NotificationUnreadSyncController({
    required Future<void> Function() reloadUnreadCount,
    required Stream<void> lifecycleSyncStream,
  }) : _reloadUnreadCount = reloadUnreadCount {
    _lifecycleSyncSubscription = lifecycleSyncStream.listen((_) {
      unawaited(syncUnreadCount());
    });
  }

  final Future<void> Function() _reloadUnreadCount;
  StreamSubscription<void>? _lifecycleSyncSubscription;
  Future<void>? _inFlightSync;
  bool _isDisposed = false;

  Future<void> syncUnreadCount() {
    if (_isDisposed) {
      return Future<void>.value();
    }
    final runningSync = _inFlightSync;
    if (runningSync != null) {
      return runningSync;
    }

    final nextSync = _runSyncUnreadCount();
    _inFlightSync = nextSync;
    return nextSync;
  }

  Future<void> _runSyncUnreadCount() async {
    try {
      await _reloadUnreadCount();
    } catch (_) {
      // NotificationNotifier already maps unread sync errors to UI state.
    } finally {
      _inFlightSync = null;
    }
  }

  void dispose() {
    _isDisposed = true;
    _lifecycleSyncSubscription?.cancel();
  }
}

final notificationUnreadCountSyncProvider =
    Provider<NotificationUnreadCountSync>((ref) {
      return (unreadCount) {
        ref
            .read(notificationUnreadCountProvider.notifier)
            .setUnreadCount(unreadCount);
      };
    });

final notificationUnreadSyncControllerProvider =
    Provider.autoDispose<NotificationUnreadSyncController>((ref) {
      final notifier = ref.watch(notificationNotifierProvider.notifier);
      final controller = NotificationUnreadSyncController(
        reloadUnreadCount: notifier.reloadUnreadCount,
        lifecycleSyncStream: ref.watch(notificationLifecycleSyncStreamProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

final notificationNotifierProvider =
    StateNotifierProvider.autoDispose<NotificationNotifier, NotificationState>((
      ref,
    ) {
      return NotificationNotifier(
        getNotificationsUseCase: ref.watch(getNotificationsUseCaseProvider),
        getUnreadCountUseCase: ref.watch(getUnreadCountUseCaseProvider),
        markAsReadUseCase: ref.watch(markAsReadUseCaseProvider),
        markAllAsReadUseCase: ref.watch(markAllAsReadUseCaseProvider),
        lifecycleSyncStream: ref.watch(notificationLifecycleSyncStreamProvider),
        onUnreadCountChanged: ref.watch(notificationUnreadCountSyncProvider),
      );
    });
