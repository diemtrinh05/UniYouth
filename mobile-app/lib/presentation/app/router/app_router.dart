import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/notifications/notification_navigation_handler.dart';
import '../../../core/permissions/camera_permission_service.dart';
import '../../../core/permissions/location_permission_service.dart';
import '../../../domain/usecases/attendance/check_attendance_status_usecase.dart';
import '../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../domain/usecases/attendance/get_my_history_usecase.dart';
import '../../../domain/usecases/auth/bootstrap_auth_usecase.dart';
import '../../../domain/usecases/auth/check_api_health_usecase.dart';
import '../../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../../domain/usecases/auth/has_local_session_usecase.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/reset_password_usecase.dart';
import '../../../domain/usecases/events/get_event_detail_usecase.dart';
import '../../../domain/usecases/events/get_event_types_usecase.dart';
import '../../../domain/usecases/events/get_events_usecase.dart';
import '../../../domain/usecases/events/get_home_event_preview_usecase.dart';
import '../../../domain/usecases/points/get_my_points_usecase.dart';
import '../../../domain/usecases/points/get_points_history_usecase.dart';
import '../../../domain/usecases/profile/change_password_usecase.dart';
import '../../../domain/usecases/profile/delete_avatar_usecase.dart';
import '../../../domain/usecases/profile/enroll_face_profile_usecase.dart';
import '../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../domain/usecases/profile/get_position_options_usecase.dart';
import '../../../domain/usecases/profile/request_face_profile_reauth_otp_usecase.dart';
import '../../../domain/usecases/profile/update_my_profile_usecase.dart';
import '../../../domain/usecases/profile/upload_avatar_usecase.dart';
import '../../../domain/usecases/registration/cancel_registration_usecase.dart';
import '../../../domain/usecases/registration/get_my_registration_usecase.dart';
import '../../../domain/usecases/registration/register_event_usecase.dart';
import '../providers/app_attendance_feature_providers.dart';
import '../providers/app_auth_feature_providers.dart';
import '../providers/app_events_feature_providers.dart';
import '../providers/app_points_feature_providers.dart';
import '../providers/app_profile_feature_providers.dart';
import '../../dev/dev_api_config_screen.dart';
import '../../features/attendance/attendance_history/attendance_history_page.dart';
import '../../features/attendance/face_capture/attendance_face_capture_service.dart';
import '../../features/attendance/qr_scan/qr_scan_page.dart';
import '../../features/attendance/qr_scan/qr_scan_page_args.dart';
import '../../features/auth/enter_otp/enter_otp_page.dart';
import '../../features/auth/forgot_password/forgot_password_page.dart';
import '../../features/auth/home_page.dart';
import '../../features/auth/login/login_page.restored.dart';
import '../../features/auth/reset_password/reset_password_page.dart';
import '../../features/events/event_detail/event_detail_page.dart';
import '../../features/events/event_filters/event_filters_page.dart';
import '../../features/events/event_list/event_list_page.dart';
import '../../features/notifications/notification_list/notification_list_page.dart';
import '../../features/points/points_history/points_history_page.dart';
import '../../features/points/points_summary/points_summary_page.dart';
import '../../features/profile/avatar/avatar_picker_service.dart';
import '../../features/profile/change_password/change_password_page.dart';
import '../../features/profile/profile_edit/profile_edit_page.dart';
import '../../features/profile/profile_view/profile_view_page.dart';
import '../../features/splash/splash_page.dart';
import '../../features/support_chat/support_chat_detail_page.dart';
import '../../features/support_chat/support_chat_list_page.dart';
import '../../navigation/app_shell_tab_navigators.dart';
import '../../navigation/main_navigation_shell.dart';
import '../../navigation/state/navigation_shell_provider.dart';
import '../../navigation/tab_navigation_coordinator.dart';
import 'app_route_stack_observer.dart';
import 'app_routes.dart';

part 'app_router_auth_routes.dart';
part 'app_router_feature_routes.dart';
part 'app_router_shell_routes.dart';
part 'app_router_support.dart';

class AppRouter {
  AppRouter({
    required AuthNavigationBindings authBindings,
    required EventsNavigationBindings eventsBindings,
    required AttendanceNavigationBindings attendanceBindings,
    required PointsNavigationBindings pointsBindings,
    required ProfileNavigationBindings profileBindings,
    required Future<bool> Function() onAuthenticatedTokenSync,
    required bool Function() consumeNotificationPermissionDeniedHint,
    required NotificationNavigationHandler notificationNavigationHandler,
    required Future<void> Function() onLogout,
    required AppRouteStackObserver routeStackObserver,
    required AppShellTabNavigationCoordinator tabNavigationCoordinator,
  }) : _authBindings = authBindings,
       _eventsBindings = eventsBindings,
       _attendanceBindings = attendanceBindings,
       _pointsBindings = pointsBindings,
       _profileBindings = profileBindings,
       _onAuthenticatedTokenSync = onAuthenticatedTokenSync,
       _consumeNotificationPermissionDeniedHint =
           consumeNotificationPermissionDeniedHint,
       _notificationNavigationHandler = notificationNavigationHandler,
       _onLogout = onLogout,
       _routeStackObserver = routeStackObserver,
       _tabNavigationCoordinator = tabNavigationCoordinator;

  final AuthNavigationBindings _authBindings;
  final EventsNavigationBindings _eventsBindings;
  final AttendanceNavigationBindings _attendanceBindings;
  final PointsNavigationBindings _pointsBindings;
  final ProfileNavigationBindings _profileBindings;
  final Future<bool> Function() _onAuthenticatedTokenSync;
  final bool Function() _consumeNotificationPermissionDeniedHint;
  final NotificationNavigationHandler _notificationNavigationHandler;
  final Future<void> Function() _onLogout;
  final AppRouteStackObserver _routeStackObserver;
  final AppShellTabNavigationCoordinator _tabNavigationCoordinator;
  RouteSettings? _pendingPostLoginRouteSettings;

  BootstrapAuthUseCase get _bootstrapAuthUseCase =>
      _authBindings.bootstrapAuthUseCase();
  HasLocalSessionUseCase get _hasLocalSessionUseCase =>
      _authBindings.hasLocalSessionUseCase();
  CheckApiHealthUseCase get _checkApiHealthUseCase =>
      _authBindings.checkApiHealthUseCase();
  LoginUseCase get _loginUseCase => _authBindings.loginUseCase();
  ForgotPasswordUseCase get _forgotPasswordUseCase =>
      _authBindings.forgotPasswordUseCase();
  ResetPasswordUseCase get _resetPasswordUseCase =>
      _authBindings.resetPasswordUseCase();
  GetEventTypesUseCase get _getEventTypesUseCase =>
      _eventsBindings.getEventTypesUseCase();
  GetEventsUseCase get _getEventsUseCase => _eventsBindings.getEventsUseCase();
  GetHomeEventPreviewUseCase get _getHomeEventPreviewUseCase =>
      _eventsBindings.getHomeEventPreviewUseCase();
  GetEventDetailUseCase get _getEventDetailUseCase =>
      _eventsBindings.getEventDetailUseCase();
  GetMyRegistrationUseCase get _getMyRegistrationUseCase =>
      _eventsBindings.getMyRegistrationUseCase();
  RegisterEventUseCase get _registerEventUseCase =>
      _eventsBindings.registerEventUseCase();
  CancelRegistrationUseCase get _cancelRegistrationUseCase =>
      _eventsBindings.cancelRegistrationUseCase();
  CheckInUseCase get _checkInUseCase => _attendanceBindings.checkInUseCase();
  CheckAttendanceStatusUseCase get _checkAttendanceStatusUseCase =>
      _attendanceBindings.checkAttendanceStatusUseCase();
  GetMyHistoryUseCase get _getMyHistoryUseCase =>
      _attendanceBindings.getMyHistoryUseCase();
  GetMyPointsUseCase get _getMyPointsUseCase =>
      _pointsBindings.getMyPointsUseCase();
  GetPointsHistoryUseCase get _getPointsHistoryUseCase =>
      _pointsBindings.getPointsHistoryUseCase();
  ChangePasswordUseCase get _changePasswordUseCase =>
      _profileBindings.changePasswordUseCase();
  GetMyProfileUseCase get _getMyProfileUseCase =>
      _profileBindings.getMyProfileUseCase();
  GetPositionOptionsUseCase get _getPositionOptionsUseCase =>
      _profileBindings.getPositionOptionsUseCase();
  UpdateMyProfileUseCase get _updateMyProfileUseCase =>
      _profileBindings.updateMyProfileUseCase();
  UploadAvatarUseCase get _uploadAvatarUseCase =>
      _profileBindings.uploadAvatarUseCase();
  DeleteAvatarUseCase get _deleteAvatarUseCase =>
      _profileBindings.deleteAvatarUseCase();
  EnrollFaceProfileUseCase get _enrollFaceProfileUseCase =>
      _profileBindings.enrollFaceProfileUseCase();
  RequestFaceProfileReauthOtpUseCase get _requestFaceProfileReauthOtpUseCase =>
      _profileBindings.requestFaceProfileReauthOtpUseCase();

  Route<dynamic> _buildProtectedRoute({
    required RouteSettings settings,
    required WidgetBuilder protectedPageBuilder,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => AuthGuardPage(
        hasLocalSessionUseCase: _hasLocalSessionUseCase,
        protectedPageBuilder: protectedPageBuilder,
      ),
    );
  }

  int? _parseEventId(Object? argument) {
    if (argument is int) {
      return argument;
    }
    if (argument is String) {
      return int.tryParse(argument);
    }
    return null;
  }

  int? _parseSupportConversationId(Object? argument) {
    if (argument is int) {
      return argument;
    }
    if (argument is String) {
      return int.tryParse(argument);
    }
    return null;
  }

  AttendanceQrScanPageArgs _parseAttendanceQrScanArgs(Object? argument) {
    if (argument is AttendanceQrScanPageArgs) {
      return argument;
    }
    if (argument is bool) {
      return AttendanceQrScanPageArgs(popOnSuccess: argument);
    }
    return const AttendanceQrScanPageArgs();
  }

  MyProfile? _parseMyProfile(Object? argument) {
    if (argument is MyProfile) {
      return argument;
    }
    return null;
  }

  NavigationShellTab _parseNavigationShellTab(Object? argument) {
    if (argument is NavigationShellTab) {
      return argument;
    }
    if (argument is int) {
      return navigationShellTabFromIndex(argument);
    }
    if (argument is String) {
      for (final tab in NavigationShellTab.values) {
        if (tab.name == argument) {
          return tab;
        }
      }
    }
    return NavigationShellTab.home;
  }

  _AppShellRouteRequest _parseAppShellRouteRequest(Object? argument) {
    if (argument is _AppShellRouteRequest) {
      return argument;
    }

    return _AppShellRouteRequest(
      initialTab: _parseNavigationShellTab(argument),
    );
  }

  NavigationShellTab _readCurrentShellTab(NavigatorState navigator) {
    try {
      final container = ProviderScope.containerOf(
        navigator.context,
        listen: false,
      );
      return container.read(navigationShellNotifierProvider).selectedTab;
    } catch (_) {
      return NavigationShellTab.home;
    }
  }

  _AppShellRouteRequest? _buildNotificationShellRequest(
    RouteSettings settings,
    NavigatorState navigator,
  ) {
    final routeName = settings.name;
    if (routeName == AppRoutes.notifications) {
      return _AppShellRouteRequest(
        initialTab: _readCurrentShellTab(navigator),
        secondaryRouteName: AppRoutes.notifications,
      );
    }

    if (routeName == AppRoutes.eventDetail) {
      final eventId = _parseEventId(settings.arguments);
      if (eventId == null || eventId <= 0) {
        return null;
      }
      return _AppShellRouteRequest(
        initialTab: NavigationShellTab.events,
        secondaryRouteName: AppRoutes.eventDetail,
        secondaryArguments: eventId,
      );
    }

    return null;
  }

  void _pushShellSecondaryRoute(
    NavigatorState navigator,
    _AppShellRouteRequest request,
  ) {
    final secondaryRouteName = request.secondaryRouteName;
    if (secondaryRouteName == null || secondaryRouteName.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) {
        return;
      }

      if (_tabNavigationCoordinator.handlesRouteInTab(
        request.initialTab,
        secondaryRouteName,
      )) {
        unawaited(
          _tabNavigationCoordinator.pushNamedInTab(
            request.initialTab,
            secondaryRouteName,
            arguments: request.secondaryArguments,
          ),
        );
        return;
      }

      unawaited(
        navigator.pushNamed(
          secondaryRouteName,
          arguments: request.secondaryArguments,
        ),
      );
    });
  }

  bool _requiresAuthForRoute(String routeName) {
    switch (routeName) {
      case AppRoutes.splash:
      case AppRoutes.login:
      case AppRoutes.forgotPassword:
      case AppRoutes.enterOtp:
      case AppRoutes.resetPassword:
        return false;
      default:
        return true;
    }
  }

  RouteSettings _normalizeNotificationTarget(
    NotificationNavigationTarget target,
  ) {
    if (target.routeName == AppRoutes.eventDetail) {
      final eventId = _parseEventId(target.arguments);
      if (eventId != null && eventId > 0) {
        return RouteSettings(name: AppRoutes.eventDetail, arguments: eventId);
      }
      return const RouteSettings(name: AppRoutes.notifications);
    }

    if (target.routeName == AppRoutes.notifications) {
      return const RouteSettings(name: AppRoutes.notifications);
    }

    if (target.routeName == AppRoutes.supportChatDetail) {
      final conversationId = _parseSupportConversationId(target.arguments);
      if (conversationId != null && conversationId > 0) {
        return RouteSettings(
          name: AppRoutes.supportChatDetail,
          arguments: conversationId,
        );
      }
      return const RouteSettings(name: AppRoutes.supportChat);
    }

    if (target.routeName == AppRoutes.supportChat) {
      return const RouteSettings(name: AppRoutes.supportChat);
    }

    return const RouteSettings(name: AppRoutes.notifications);
  }

  void _storePendingPostLoginRouteSettings(RouteSettings settings) {
    final routeName = settings.name;
    if (routeName == null || routeName.isEmpty) {
      return;
    }
    _pendingPostLoginRouteSettings = settings;
  }

  RouteSettings? _takePendingPostLoginRouteSettings() {
    final pendingSettings = _pendingPostLoginRouteSettings;
    _pendingPostLoginRouteSettings = null;
    return pendingSettings;
  }

  Future<bool> continuePendingPostLoginNavigation({
    required NavigatorState navigator,
  }) async {
    if (!navigator.mounted) {
      return false;
    }

    final pendingSettings = _takePendingPostLoginRouteSettings();
    final routeName = pendingSettings?.name;
    if (pendingSettings == null || routeName == null || routeName.isEmpty) {
      return false;
    }

    final shellRequest = _buildNotificationShellRequest(
      pendingSettings,
      navigator,
    );
    if (shellRequest != null) {
      await navigator.pushNamedAndRemoveUntil(
        AppRoutes.app,
        (_) => false,
        arguments: shellRequest,
      );
      return true;
    }

    await navigator.pushNamedAndRemoveUntil(
      routeName,
      (_) => false,
      arguments: pendingSettings.arguments,
    );
    return true;
  }

  Future<RouteSettings> resolveNotificationRouteSettings(
    Map<String, dynamic>? payload,
  ) async {
    final target = _notificationNavigationHandler.resolveTarget(payload);
    final normalizedSettings = _normalizeNotificationTarget(target);
    final routeName = normalizedSettings.name ?? AppRoutes.notifications;

    if (!_requiresAuthForRoute(routeName)) {
      return normalizedSettings;
    }

    final hasLocalSession = await _hasLocalSessionUseCase();
    if (!hasLocalSession) {
      _storePendingPostLoginRouteSettings(normalizedSettings);
      return const RouteSettings(name: AppRoutes.login);
    }

    return normalizedSettings;
  }

  Future<void> navigateFromNotificationPayload({
    required NavigatorState navigator,
    Map<String, dynamic>? payload,
  }) async {
    if (!navigator.mounted) {
      return;
    }

    final settings = await resolveNotificationRouteSettings(payload);
    final routeName = settings.name;
    if (routeName == null || routeName.isEmpty) {
      return;
    }

    if (routeName == AppRoutes.login) {
      await navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      return;
    }

    final shellRequest = _buildNotificationShellRequest(settings, navigator);
    if (shellRequest != null) {
      if (_routeStackObserver.containsRoute(AppRoutes.app)) {
        navigator.popUntil((route) => route.settings.name == AppRoutes.app);
        if (navigator.mounted) {
          final container = ProviderScope.containerOf(
            navigator.context,
            listen: false,
          );
          container
              .read(navigationShellNotifierProvider.notifier)
              .selectTab(shellRequest.initialTab);
          _pushShellSecondaryRoute(navigator, shellRequest);
        }
        return;
      }

      unawaited(
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.app,
          (_) => false,
          arguments: shellRequest,
        ),
      );
      return;
    }

    unawaited(navigator.pushNamed(routeName, arguments: settings.arguments));
  }

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == AppRoutes.devApiConfig) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const DevApiConfigScreen(),
      );
    }

    switch (settings.name) {
      case AppRoutes.splash:
        return _buildSplashRoute(settings);
      case AppRoutes.login:
        return _buildLoginRoute(settings);
      case AppRoutes.forgotPassword:
        return _buildForgotPasswordRoute(settings);
      case AppRoutes.enterOtp:
        return _buildEnterOtpRoute(settings);
      case AppRoutes.resetPassword:
        return _buildResetPasswordRoute(settings);
      case AppRoutes.app:
        return _buildAppShellRoute(settings);
      case AppRoutes.home:
        return _buildHomeRedirectRoute(settings);
      case AppRoutes.eventFilters:
        return _buildEventFiltersRoute(settings);
      case AppRoutes.eventList:
        return _buildEventListRoute(settings);
      case AppRoutes.eventDetail:
        return _buildEventDetailRoute(settings);
      case AppRoutes.attendanceQrScan:
        return _buildAttendanceQrScanRoute(settings);
      case AppRoutes.attendanceHistory:
        return _buildAttendanceHistoryRoute(settings);
      case AppRoutes.pointsSummary:
        return _buildPointsSummaryRoute(settings);
      case AppRoutes.pointsHistory:
        return _buildPointsHistoryRoute(settings);
      case AppRoutes.profileView:
        return _buildProfileViewRoute(settings);
      case AppRoutes.profileEdit:
        return _buildProfileEditRoute(settings);
      case AppRoutes.profileChangePassword:
        return _buildProfileChangePasswordRoute(settings);
      case AppRoutes.notifications:
        return _buildNotificationsRoute(settings);
      case AppRoutes.supportChat:
        return _buildSupportChatRoute(settings);
      case AppRoutes.supportChatDetail:
        return _buildSupportChatDetailRoute(settings);
      default:
        return _buildFallbackLoginRoute(settings);
    }
  }
}
