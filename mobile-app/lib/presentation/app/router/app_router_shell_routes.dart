part of 'app_router.dart';

extension _AppRouterShellRoutes on AppRouter {
  Route<dynamic> _buildAppShellRoute(RouteSettings settings) {
    final shellRequest = _parseAppShellRouteRequest(settings.arguments);
    final avatarPickerService = FilePickerAvatarPickerService();

    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (context) => _AppShellRoutePage(
        request: shellRequest,
        tabNavigationCoordinator: _tabNavigationCoordinator,
        child: MainNavigationShell(
          tabNavigationCoordinator: _tabNavigationCoordinator,
          homeTab: HomePage(
            onLogout: _onLogout,
            getMyProfileUseCase: _getMyProfileUseCase,
            getHomeEventPreviewUseCase: _getHomeEventPreviewUseCase,
          ),
          eventsTab: EventsTabNavigator(
            coordinator: _tabNavigationCoordinator,
            getEventTypesUseCase: _getEventTypesUseCase,
            getEventsUseCase: _getEventsUseCase,
            getEventDetailUseCase: _getEventDetailUseCase,
            getMyRegistrationUseCase: _getMyRegistrationUseCase,
            registerEventUseCase: _registerEventUseCase,
            cancelRegistrationUseCase: _cancelRegistrationUseCase,
            checkAttendanceStatusUseCase: _checkAttendanceStatusUseCase,
          ),
          pointsTab: PointsTabNavigator(
            coordinator: _tabNavigationCoordinator,
            getMyPointsUseCase: _getMyPointsUseCase,
            getPointsHistoryUseCase: _getPointsHistoryUseCase,
          ),
          profileTab: ProfileTabNavigator(
            coordinator: _tabNavigationCoordinator,
            getMyProfileUseCase: _getMyProfileUseCase,
            getPositionOptionsUseCase: _getPositionOptionsUseCase,
            updateMyProfileUseCase: _updateMyProfileUseCase,
            uploadAvatarUseCase: _uploadAvatarUseCase,
            deleteAvatarUseCase: _deleteAvatarUseCase,
            enrollFaceProfileUseCase: _enrollFaceProfileUseCase,
            requestFaceProfileReauthOtpUseCase:
                _requestFaceProfileReauthOtpUseCase,
            changePasswordUseCase: _changePasswordUseCase,
            avatarPickerService: avatarPickerService,
            faceCaptureService: CameraAttendanceFaceCaptureService(),
          ),
          initialIndex: shellRequest.initialTab.index,
          onQrTap: () {
            Navigator.of(context).pushNamed(AppRoutes.attendanceQrScan);
          },
        ),
      ),
    );
  }

  Route<dynamic> _buildHomeRedirectRoute(RouteSettings settings) {
    return _buildProtectedRoute(
      settings: settings,
      protectedPageBuilder: (_) => const _HomeRouteRedirectPage(),
    );
  }
}
