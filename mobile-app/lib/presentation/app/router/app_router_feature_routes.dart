part of 'app_router.dart';

extension _AppRouterFeatureRoutes on AppRouter {
  Route<dynamic> _buildEventFiltersRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) =>
          EventFiltersPage(getEventTypesUseCase: _getEventTypesUseCase),
    );
  }

  Route<dynamic> _buildEventListRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) => EventListPage(
        getEventsUseCase: _getEventsUseCase,
        getEventTypesUseCase: _getEventTypesUseCase,
      ),
    );
  }

  Route<dynamic> _buildEventDetailRoute(RouteSettings settings) {
    final eventId = _parseEventId(settings.arguments);
    if (eventId == null) {
      return _buildProtectedRoute(
        settings: settings,
        protectedPageBuilder: (_) => EventListPage(
          getEventsUseCase: _getEventsUseCase,
          getEventTypesUseCase: _getEventTypesUseCase,
        ),
      );
    }

    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) => EventDetailPage(
        eventId: eventId,
        getEventDetailUseCase: _getEventDetailUseCase,
        getMyRegistrationUseCase: _getMyRegistrationUseCase,
        registerEventUseCase: _registerEventUseCase,
        cancelRegistrationUseCase: _cancelRegistrationUseCase,
        checkAttendanceStatusUseCase: _checkAttendanceStatusUseCase,
      ),
    );
  }

  Route<dynamic> _buildAttendanceQrScanRoute(RouteSettings settings) {
    final routeArgs = _parseAttendanceQrScanArgs(settings.arguments);

    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) => QrScanPage(
        cameraPermissionService: PermissionHandlerCameraPermissionService(),
        locationPermissionService: PermissionHandlerLocationPermissionService(),
        locationService: GeolocatorLocationService(),
        checkInUseCase: _checkInUseCase,
        faceCaptureService: CameraAttendanceFaceCaptureService(),
        popOnSuccess: routeArgs.popOnSuccess,
        enableFaceVerification: routeArgs.enableFaceVerification,
      ),
    );
  }

  Route<dynamic> _buildAttendanceHistoryRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) =>
          AttendanceHistoryPage(getMyHistoryUseCase: _getMyHistoryUseCase),
    );
  }

  Route<dynamic> _buildPointsSummaryRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) =>
          PointsSummaryPage(getMyPointsUseCase: _getMyPointsUseCase),
    );
  }

  Route<dynamic> _buildPointsHistoryRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) =>
          PointsHistoryPage(getPointsHistoryUseCase: _getPointsHistoryUseCase),
    );
  }

  Route<dynamic> _buildProfileViewRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) => ProfileViewPage(
        getMyProfileUseCase: _getMyProfileUseCase,
        uploadAvatarUseCase: _uploadAvatarUseCase,
        deleteAvatarUseCase: _deleteAvatarUseCase,
        enrollFaceProfileUseCase: _enrollFaceProfileUseCase,
        requestFaceProfileReauthOtpUseCase: _requestFaceProfileReauthOtpUseCase,
        avatarPickerService: FilePickerAvatarPickerService(),
        faceCaptureService: CameraAttendanceFaceCaptureService(),
      ),
    );
  }

  Route<dynamic> _buildProfileEditRoute(RouteSettings settings) {
    final profile = _parseMyProfile(settings.arguments);
    if (profile == null) {
      return _buildProfileViewRoute(settings);
    }

    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) => ProfileEditPage(
        initialProfile: profile,
        getPositionOptionsUseCase: _getPositionOptionsUseCase,
        updateMyProfileUseCase: _updateMyProfileUseCase,
      ),
    );
  }

  Route<dynamic> _buildProfileChangePasswordRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) =>
          ChangePasswordPage(changePasswordUseCase: _changePasswordUseCase),
    );
  }

  Route<dynamic> _buildNotificationsRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) => const NotificationListPage(),
    );
  }

  Route<dynamic> _buildSupportChatRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) => const SupportChatListPage(),
    );
  }

  Route<dynamic> _buildSupportChatDetailRoute(RouteSettings settings) {
    final conversationId = _parseSupportConversationId(settings.arguments);
    if (conversationId == null || conversationId <= 0) {
      return _buildSupportChatRoute(settings);
    }

    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) =>
          SupportChatDetailPage(conversationId: conversationId),
    );
  }
}
