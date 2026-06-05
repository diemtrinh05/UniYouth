part of 'app_router.dart';

extension _AppRouterAuthRoutes on AppRouter {
  Route<dynamic> _buildSplashRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => SplashPage(
        loginUseCase: _loginUseCase,
        bootstrapAuthUseCase: _bootstrapAuthUseCase,
        checkApiHealthUseCase: _checkApiHealthUseCase,
        onAuthenticatedTokenSync: _onAuthenticatedTokenSync,
        consumeNotificationPermissionDeniedHint:
            _consumeNotificationPermissionDeniedHint,
      ),
    );
  }

  Route<dynamic> _buildLoginRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => LoginPage(
        loginUseCase: _loginUseCase,
        onAuthenticatedTokenSync: _onAuthenticatedTokenSync,
        consumeNotificationPermissionDeniedHint:
            _consumeNotificationPermissionDeniedHint,
        onPendingPostLoginNavigation: (navigator) {
          return continuePendingPostLoginNavigation(navigator: navigator);
        },
      ),
    );
  }

  Route<dynamic> _buildForgotPasswordRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) =>
          ForgotPasswordPage(forgotPasswordUseCase: _forgotPasswordUseCase),
    );
  }

  Route<dynamic> _buildEnterOtpRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const EnterOtpPage(),
    );
  }

  Route<dynamic> _buildResetPasswordRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) =>
          ResetPasswordPage(resetPasswordUseCase: _resetPasswordUseCase),
    );
  }

  Route<dynamic> _buildFallbackLoginRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => LoginPage(
        loginUseCase: _loginUseCase,
        onAuthenticatedTokenSync: _onAuthenticatedTokenSync,
        consumeNotificationPermissionDeniedHint:
            _consumeNotificationPermissionDeniedHint,
        onPendingPostLoginNavigation: (navigator) {
          return continuePendingPostLoginNavigation(navigator: navigator);
        },
      ),
    );
  }
}
