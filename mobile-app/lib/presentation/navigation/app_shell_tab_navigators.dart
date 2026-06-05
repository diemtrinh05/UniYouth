import 'package:flutter/material.dart';

import '../../domain/usecases/attendance/check_attendance_status_usecase.dart';
import '../../domain/usecases/events/get_event_detail_usecase.dart';
import '../../domain/usecases/events/get_event_types_usecase.dart';
import '../../domain/usecases/events/get_events_usecase.dart';
import '../../domain/usecases/points/get_my_points_usecase.dart';
import '../../domain/usecases/points/get_points_history_usecase.dart';
import '../../domain/usecases/profile/change_password_usecase.dart';
import '../../domain/usecases/profile/delete_avatar_usecase.dart';
import '../../domain/usecases/profile/enroll_face_profile_usecase.dart';
import '../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../domain/usecases/profile/get_position_options_usecase.dart';
import '../../domain/usecases/profile/request_face_profile_reauth_otp_usecase.dart';
import '../../domain/usecases/profile/update_my_profile_usecase.dart';
import '../../domain/usecases/profile/upload_avatar_usecase.dart';
import '../../domain/usecases/registration/cancel_registration_usecase.dart';
import '../../domain/usecases/registration/get_my_registration_usecase.dart';
import '../../domain/usecases/registration/register_event_usecase.dart';
import '../app/router/app_routes.dart';
import '../features/events/event_detail/event_detail_page.dart';
import '../features/events/event_list/event_list_page.dart';
import '../features/points/points_history/points_history_page.dart';
import '../features/points/points_summary/points_summary_page.dart';
import '../features/attendance/face_capture/attendance_face_capture_service.dart';
import '../features/profile/avatar/avatar_picker_service.dart';
import '../features/profile/change_password/change_password_page.dart';
import '../features/profile/profile_edit/profile_edit_page.dart';
import '../features/profile/profile_view/profile_view_page.dart';
import 'tab_navigation_coordinator.dart';

class EventsTabNavigator extends StatelessWidget {
  const EventsTabNavigator({
    super.key,
    required this.coordinator,
    required this.getEventTypesUseCase,
    required this.getEventsUseCase,
    required this.getEventDetailUseCase,
    required this.getMyRegistrationUseCase,
    required this.registerEventUseCase,
    required this.cancelRegistrationUseCase,
    required this.checkAttendanceStatusUseCase,
  });

  final AppShellTabNavigationCoordinator coordinator;
  final GetEventTypesUseCase getEventTypesUseCase;
  final GetEventsUseCase getEventsUseCase;
  final GetEventDetailUseCase getEventDetailUseCase;
  final GetMyRegistrationUseCase getMyRegistrationUseCase;
  final RegisterEventUseCase registerEventUseCase;
  final CancelRegistrationUseCase cancelRegistrationUseCase;
  final CheckAttendanceStatusUseCase checkAttendanceStatusUseCase;

  @override
  Widget build(BuildContext context) {
    return _ShellTabNavigator(
      navigatorKey: coordinator.eventsNavigatorKey,
      rootPageBuilder: (_) => EventListPage(
        getEventsUseCase: getEventsUseCase,
        getEventTypesUseCase: getEventTypesUseCase,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.eventDetail:
            final eventId = _parseEventId(settings.arguments);
            if (eventId == null) {
              return null;
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => EventDetailPage(
                eventId: eventId,
                getEventDetailUseCase: getEventDetailUseCase,
                getMyRegistrationUseCase: getMyRegistrationUseCase,
                registerEventUseCase: registerEventUseCase,
                cancelRegistrationUseCase: cancelRegistrationUseCase,
                checkAttendanceStatusUseCase: checkAttendanceStatusUseCase,
              ),
            );
        }
        return null;
      },
    );
  }
}

class PointsTabNavigator extends StatelessWidget {
  const PointsTabNavigator({
    super.key,
    required this.coordinator,
    required this.getMyPointsUseCase,
    required this.getPointsHistoryUseCase,
  });

  final AppShellTabNavigationCoordinator coordinator;
  final GetMyPointsUseCase getMyPointsUseCase;
  final GetPointsHistoryUseCase getPointsHistoryUseCase;

  @override
  Widget build(BuildContext context) {
    return _ShellTabNavigator(
      navigatorKey: coordinator.pointsNavigatorKey,
      rootPageBuilder: (_) =>
          PointsSummaryPage(getMyPointsUseCase: getMyPointsUseCase),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.pointsHistory:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => PointsHistoryPage(
                getPointsHistoryUseCase: getPointsHistoryUseCase,
              ),
            );
        }
        return null;
      },
    );
  }
}

class ProfileTabNavigator extends StatelessWidget {
  const ProfileTabNavigator({
    super.key,
    required this.coordinator,
    required this.getMyProfileUseCase,
    required this.getPositionOptionsUseCase,
    required this.updateMyProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.deleteAvatarUseCase,
    required this.enrollFaceProfileUseCase,
    required this.requestFaceProfileReauthOtpUseCase,
    required this.changePasswordUseCase,
    required this.avatarPickerService,
    required this.faceCaptureService,
  });

  final AppShellTabNavigationCoordinator coordinator;
  final GetMyProfileUseCase getMyProfileUseCase;
  final GetPositionOptionsUseCase getPositionOptionsUseCase;
  final UpdateMyProfileUseCase updateMyProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final DeleteAvatarUseCase deleteAvatarUseCase;
  final EnrollFaceProfileUseCase enrollFaceProfileUseCase;
  final RequestFaceProfileReauthOtpUseCase requestFaceProfileReauthOtpUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final AvatarPickerService avatarPickerService;
  final AttendanceFaceCaptureService faceCaptureService;

  @override
  Widget build(BuildContext context) {
    return _ShellTabNavigator(
      navigatorKey: coordinator.profileNavigatorKey,
      rootPageBuilder: (_) => ProfileViewPage(
        getMyProfileUseCase: getMyProfileUseCase,
        uploadAvatarUseCase: uploadAvatarUseCase,
        deleteAvatarUseCase: deleteAvatarUseCase,
        enrollFaceProfileUseCase: enrollFaceProfileUseCase,
        requestFaceProfileReauthOtpUseCase: requestFaceProfileReauthOtpUseCase,
        avatarPickerService: avatarPickerService,
        faceCaptureService: faceCaptureService,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.profileEdit:
            final profile = settings.arguments;
            if (profile is! MyProfile) {
              return null;
            }
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => ProfileEditPage(
                initialProfile: profile,
                getPositionOptionsUseCase: getPositionOptionsUseCase,
                updateMyProfileUseCase: updateMyProfileUseCase,
              ),
            );
          case AppRoutes.profileChangePassword:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ChangePasswordPage(
                changePasswordUseCase: changePasswordUseCase,
              ),
            );
        }
        return null;
      },
    );
  }
}

class _ShellTabNavigator extends StatelessWidget {
  const _ShellTabNavigator({
    required this.navigatorKey,
    required this.rootPageBuilder,
    required this.onGenerateRoute,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final WidgetBuilder rootPageBuilder;
  final Route<dynamic>? Function(RouteSettings settings) onGenerateRoute;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: Navigator.defaultRouteName,
      onGenerateRoute: (settings) {
        if (settings.name == Navigator.defaultRouteName) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: rootPageBuilder,
          );
        }

        return onGenerateRoute(settings);
      },
    );
  }
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
