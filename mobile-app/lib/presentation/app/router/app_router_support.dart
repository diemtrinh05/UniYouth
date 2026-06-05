part of 'app_router.dart';

class _AppShellRouteRequest {
  const _AppShellRouteRequest({
    required this.initialTab,
    this.secondaryRouteName,
    this.secondaryArguments,
  });

  final NavigationShellTab initialTab;
  final String? secondaryRouteName;
  final Object? secondaryArguments;
}

class _AppShellRoutePage extends StatefulWidget {
  const _AppShellRoutePage({
    required this.request,
    required this.tabNavigationCoordinator,
    required this.child,
  });

  final _AppShellRouteRequest request;
  final AppShellTabNavigationCoordinator tabNavigationCoordinator;
  final Widget child;

  @override
  State<_AppShellRoutePage> createState() => _AppShellRoutePageState();
}

class _AppShellRoutePageState extends State<_AppShellRoutePage> {
  bool _didOpenSecondaryRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didOpenSecondaryRoute) {
      return;
    }

    final secondaryRouteName = widget.request.secondaryRouteName;
    if (secondaryRouteName == null || secondaryRouteName.isEmpty) {
      return;
    }

    _didOpenSecondaryRoute = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (widget.tabNavigationCoordinator.handlesRouteInTab(
        widget.request.initialTab,
        secondaryRouteName,
      )) {
        unawaited(
          widget.tabNavigationCoordinator.pushNamedInTab(
            widget.request.initialTab,
            secondaryRouteName,
            arguments: widget.request.secondaryArguments,
          ),
        );
        return;
      }

      unawaited(
        Navigator.of(context).pushNamed(
          secondaryRouteName,
          arguments: widget.request.secondaryArguments,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _HomeRouteRedirectPage extends StatefulWidget {
  const _HomeRouteRedirectPage();

  @override
  State<_HomeRouteRedirectPage> createState() => _HomeRouteRedirectPageState();
}

class _HomeRouteRedirectPageState extends State<_HomeRouteRedirectPage> {
  bool _didRedirect = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRedirect) {
      return;
    }

    _didRedirect = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.app, arguments: NavigationShellTab.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

final authGuardSessionProvider = FutureProvider.autoDispose.family<
  bool,
  HasLocalSessionUseCase
>((ref, hasLocalSessionUseCase) async {
  return hasLocalSessionUseCase();
});

class AuthGuardPage extends ConsumerStatefulWidget {
  const AuthGuardPage({
    super.key,
    required this.hasLocalSessionUseCase,
    required this.protectedPageBuilder,
  });

  final HasLocalSessionUseCase hasLocalSessionUseCase;
  final WidgetBuilder protectedPageBuilder;

  @override
  ConsumerState<AuthGuardPage> createState() => _AuthGuardPageState();
}

class _AuthGuardPageState extends ConsumerState<AuthGuardPage> {
  @override
  Widget build(BuildContext context) {
    final guardProvider = authGuardSessionProvider(
      widget.hasLocalSessionUseCase,
    );

    ref.listen<AsyncValue<bool>>(guardProvider, (previous, next) {
      next.whenData((hasLocalSession) {
        if (hasLocalSession || !mounted) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        });
      });
    });

    final guardState = ref.watch(guardProvider);
    return guardState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (hasLocalSession) {
        if (!hasLocalSession) {
          return const SizedBox.shrink();
        }
        return widget.protectedPageBuilder(context);
      },
      error: (error, stackTrace) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
