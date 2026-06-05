import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../domain/usecases/auth/bootstrap_auth_usecase.dart';
import '../../../domain/usecases/auth/check_api_health_usecase.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../auth/state/auth_provider.dart';
import '../auth/state/auth_state.dart';
import '../../shared/mappers/notification_error_ui_mapper.dart';
import '../../app/router/app_routes.dart';

// ─── Design Tokens (Light Theme) ───────────────────────────────────────────
const _kBg = Color(0xFFF0F7FF); // nền sáng blue-tinted
const _kBlue = Color(0xFF1565C0); // primary
const _kBlueDark = Color(0xFF0D47A1); // dark accent
const _kBlueMid = Color(0xFF1976D2); // gradient mid
const _kBlueSky = Color(0xFF42A5F5); // accent sky
const _kCyan = Color(0xFF00BCD4); // call-to-action cyan
const _kBlueLight = Color(0xFFE3F2FD); // card/surface light
const _kTextMid = Color(0xFF546E7A); // text secondary

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    required this.loginUseCase,
    required this.bootstrapAuthUseCase,
    required this.checkApiHealthUseCase,
    required this.onAuthenticatedTokenSync,
    required this.consumeNotificationPermissionDeniedHint,
  });

  final LoginUseCase loginUseCase;
  final BootstrapAuthUseCase bootstrapAuthUseCase;
  final CheckApiHealthUseCase checkApiHealthUseCase;
  final Future<bool> Function() onAuthenticatedTokenSync;
  final bool Function() consumeNotificationPermissionDeniedHint;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _exitCtrl;

  // ── Animations ────────────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _dotsFade;
  late final Animation<double> _exitFade;

  bool _animEntryDone = false;
  bool _isNavigationScheduled = false;
  bool _isBootstrapping = false;
  String? _healthCheckErrorMessage;
  late final AuthNotifierDependencies _authDependencies;

  @override
  void initState() {
    super.initState();
    _authDependencies = AuthNotifierDependencies(
      loginUseCase: widget.loginUseCase,
      onAuthenticatedTokenSync: widget.onAuthenticatedTokenSync,
      consumeNotificationPermissionDeniedHint:
          widget.consumeNotificationPermissionDeniedHint,
    );

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic),
          ),
        );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );
    _exitFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic));

    _entryCtrl.forward().whenComplete(() {
      _animEntryDone = true;
      _maybeNavigate();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _ringCtrl.dispose();
    _dotsCtrl.dispose();
    _shimmerCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_isBootstrapping) {
      return;
    }
    _isBootstrapping = true;
    if (_healthCheckErrorMessage != null && mounted) {
      setState(() {
        _healthCheckErrorMessage = null;
      });
    }

    final isHealthy = await widget.checkApiHealthUseCase().timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );

    if (!mounted) {
      _isBootstrapping = false;
      return;
    }

    if (!isHealthy) {
      setState(() {
        _healthCheckErrorMessage =
            'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.';
      });
      _isBootstrapping = false;
      return;
    }

    final notifier = ref.read(
      authNotifierByDependenciesProvider(_authDependencies).notifier,
    );
    await notifier.bootstrap(
      loadStatus: () async {
        final status = await widget.bootstrapAuthUseCase();
        if (status == AuthBootstrapResult.authenticated) {
          return AuthBootstrapUiStatus.authenticated;
        }
        return AuthBootstrapUiStatus.unauthenticated;
      },
    );
    if (!mounted) {
      _isBootstrapping = false;
      return;
    }
    _isBootstrapping = false;
    _maybeNavigate();
  }

  void _maybeNavigate() {
    if (!_animEntryDone || _isNavigationScheduled) {
      return;
    }
    final authState = ref.read(
      authNotifierByDependenciesProvider(_authDependencies),
    );
    final status = authState.bootstrapStatus;
    if (status == AuthBootstrapUiStatus.initial ||
        status == AuthBootstrapUiStatus.checking) {
      return;
    }

    _isNavigationScheduled = true;
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      await _exitCtrl.forward();
      if (!mounted) return;
      if (status == AuthBootstrapUiStatus.unauthenticated) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      final notifier = ref.read(
        authNotifierByDependenciesProvider(_authDependencies).notifier,
      );
      await notifier.resolvePostAuthentication(
        onAuthenticatedTokenSync: widget.onAuthenticatedTokenSync,
        consumeNotificationPermissionDeniedHint:
            widget.consumeNotificationPermissionDeniedHint,
      );
      if (!mounted) return;

      final nextState = ref.read(
        authNotifierByDependenciesProvider(_authDependencies),
      );
      if (nextState.handledInitialNotificationNavigation) {
        return;
      }

      if (nextState.shouldPromptNotificationPermissionSettings) {
        await _showNotificationPermissionSettingsPrompt();
        if (!mounted) return;
        notifier.consumeNotificationPermissionPromptSignal();
      }

      final currentState = ref.read(
        authNotifierByDependenciesProvider(_authDependencies),
      );
      if (currentState.shouldNavigateToHome) {
        notifier.consumeNavigateToHomeSignal();
        Navigator.of(context).pushReplacementNamed(AppRoutes.app);
      }
    });
  }

  Future<void> _showNotificationPermissionSettingsPrompt() async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quyền thông báo'),
          content: Text(
            NotificationErrorUiMapper.permissionDeniedGuidanceMessage(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(NotificationErrorUiMapper.remindLaterLabel()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(NotificationErrorUiMapper.openSettingsLabel()),
            ),
          ],
        );
      },
    );

    if (shouldOpenSettings == true) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      authNotifierByDependenciesProvider(
        _authDependencies,
      ).select((state) => state.bootstrapStatus),
    );
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _bgCtrl,
            _entryCtrl,
            _ringCtrl,
            _dotsCtrl,
            _shimmerCtrl,
            _exitCtrl,
          ]),
          builder: (context, _) {
            return FadeTransition(
              opacity: _exitFade,
              child: Stack(
                children: [
                  // ── Light animated background ────────────────────────────
                  Positioned.fill(
                    child: CustomPaint(painter: _BgPainter(_bgCtrl.value)),
                  ),

                  // ── Dot grid overlay (subtle) ─────────────────────────────
                  Positioned.fill(
                    child: CustomPaint(painter: _DotGridPainter()),
                  ),

                  // ── Soft glow rings behind logo ───────────────────────────
                  Center(
                    child: _GlowRing(
                      rotationValue: _ringCtrl.value,
                      entryProgress: _entryCtrl.value,
                    ),
                  ),

                  // ── Main content ─────────────────────────────────────────
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: _LogoBox(shimmer: _shimmerCtrl.value),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // App name
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleFade,
                            child: const _AppTitle(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        SlideTransition(
                          position: _subtitleSlide,
                          child: FadeTransition(
                            opacity: _subtitleFade,
                            child: const _Subtitle(),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Loading dots
                        FadeTransition(
                          opacity: _dotsFade,
                          child: _LoadingDots(progress: _dotsCtrl.value),
                        ),
                        if (_healthCheckErrorMessage != null) ...[
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _healthCheckErrorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: _kTextMid.withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isBootstrapping
                                ? null
                                : () => unawaited(_bootstrap()),
                            child: const Text('Thử lại'),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.devApiConfig);
                          },
                          child: const Text('Dev API Config'),
                        ),
                      ],
                    ),
                  ),

                  // ── Decorative corner accents ─────────────────────────────
                  ..._buildCornerAccents(size),

                  // ── Version stamp ─────────────────────────────────────────
                  Positioned(
                    bottom: 32 + MediaQuery.of(context).padding.bottom,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _dotsFade,
                      child: Text(
                        'v1.0.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.5,
                          color: _kTextMid.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildCornerAccents(Size size) {
    return [
      // Top-left cluster
      Positioned(
        top: 56 + MediaQuery.of(context).padding.top,
        left: 28,
        child: _CornerDot(dotSize: 8, color: _kBlueSky.withValues(alpha: 0.35)),
      ),
      Positioned(
        top: 78 + MediaQuery.of(context).padding.top,
        left: 50,
        child: _CornerDot(dotSize: 5, color: _kCyan.withValues(alpha: 0.25)),
      ),
      Positioned(
        top: 64 + MediaQuery.of(context).padding.top,
        left: 68,
        child: _CornerDot(dotSize: 3, color: _kBlue.withValues(alpha: 0.2)),
      ),

      // Top-right cluster
      Positioned(
        top: 60 + MediaQuery.of(context).padding.top,
        right: 32,
        child: _CornerDot(dotSize: 7, color: _kCyan.withValues(alpha: 0.3)),
      ),
      Positioned(
        top: 82 + MediaQuery.of(context).padding.top,
        right: 56,
        child: _CornerDot(dotSize: 4, color: _kBlueSky.withValues(alpha: 0.25)),
      ),

      // Bottom-right cluster
      Positioned(
        bottom: 100,
        right: 36,
        child: _CornerDot(
          dotSize: 9,
          color: _kBlueLight.withValues(alpha: 0.8),
        ),
      ),
      Positioned(
        bottom: 124,
        right: 62,
        child: _CornerDot(dotSize: 5, color: _kBlueSky.withValues(alpha: 0.3)),
      ),
      Positioned(
        bottom: 108,
        right: 80,
        child: _CornerDot(dotSize: 3, color: _kCyan.withValues(alpha: 0.2)),
      ),

      // Bottom-left cluster
      Positioned(
        bottom: 112,
        left: 28,
        child: _CornerDot(dotSize: 6, color: _kBlueSky.withValues(alpha: 0.3)),
      ),
      Positioned(
        bottom: 92,
        left: 52,
        child: _CornerDot(dotSize: 4, color: _kCyan.withValues(alpha: 0.2)),
      ),
    ];
  }
}

// ─── Glow Ring ────────────────────────────────────────────────────────────────
class _GlowRing extends StatelessWidget {
  const _GlowRing({required this.rotationValue, required this.entryProgress});
  final double rotationValue;
  final double entryProgress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft glow halo
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _kBlueSky.withValues(alpha: 0.12 * entryProgress),
                _kBg.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        // Rotating dashed ring
        Transform.rotate(
          angle: rotationValue * 2 * math.pi,
          child: SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: _ArcRingPainter(entryProgress, isLight: true),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Logo Box ─────────────────────────────────────────────────────────────────
class _LogoBox extends StatelessWidget {
  const _LogoBox({required this.shimmer});
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlue, _kBlueMid, _kCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: _kCyan.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CustomPaint(
              painter: _ShimmerPainter(shimmer),
              child: const SizedBox.expand(),
            ),
          ),
          const Center(
            child: Icon(Icons.school_rounded, size: 52, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─── App Title ────────────────────────────────────────────────────────────────
class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [_kBlueDark, _kBlueMid, _kCyan],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: const Text(
        'UniYouth',
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: Colors.white, // masked by ShaderMask
          letterSpacing: -0.5,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─── Subtitle ─────────────────────────────────────────────────────────────────
class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kBlueSky, _kCyan]),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Học tập không giới hạn',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _kTextMid.withValues(alpha: 0.85),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 20,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_kCyan, _kBlueSky]),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

// ─── Loading Dots ─────────────────────────────────────────────────────────────
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (progress - i * 0.25).abs();
        final scale = phase < 0.5 ? 1.0 + (0.5 - phase) * 0.7 : 1.0;
        final opacity = 0.3 + (1.0 - (phase * 2).clamp(0.0, 1.0)) * 0.7;

        // Alternate dot colors: blue → sky → cyan
        final colors = [_kBlue, _kBlueSky, _kCyan];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Transform.scale(
            scale: scale.clamp(1.0, 1.35),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i].withValues(alpha: opacity.clamp(0.3, 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: colors[i].withValues(alpha: 0.3 * opacity),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Corner Dot ──────────────────────────────────────────────────────────────
class _CornerDot extends StatelessWidget {
  const _CornerDot({required this.dotSize, required this.color});
  final double dotSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

/// Light animated background — soft floating blue orbs on white-blue base
class _BgPainter extends CustomPainter {
  _BgPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _kBg,
    );

    // Orb 1 — top-right, sky blue
    final orb1x = size.width * (0.78 + 0.07 * math.sin(t * math.pi));
    final orb1y = size.height * (0.14 + 0.05 * math.cos(t * math.pi));
    _drawOrb(
      canvas,
      Offset(orb1x, orb1y),
      size.width * 0.6,
      _kBlueSky.withValues(alpha: 0.12),
      _kBg.withValues(alpha: 0.0),
    );

    // Orb 2 — bottom-left, primary blue
    final orb2x = size.width * (0.12 - 0.05 * math.sin(t * math.pi));
    final orb2y = size.height * (0.8 + 0.04 * math.cos(t * math.pi));
    _drawOrb(
      canvas,
      Offset(orb2x, orb2y),
      size.width * 0.65,
      _kBlue.withValues(alpha: 0.07),
      _kBg.withValues(alpha: 0.0),
    );

    // Orb 3 — center, cyan hint
    _drawOrb(
      canvas,
      Offset(size.width * 0.5, size.height * 0.45),
      size.width * 0.45,
      _kCyan.withValues(alpha: 0.05),
      _kBg.withValues(alpha: 0.0),
    );

    // Orb 4 — top-left, mid blue
    final orb4x = size.width * (0.1 + 0.04 * math.cos(t * math.pi));
    final orb4y = size.height * (0.18 - 0.03 * math.sin(t * math.pi));
    _drawOrb(
      canvas,
      Offset(orb4x, orb4y),
      size.width * 0.4,
      _kBlueMid.withValues(alpha: 0.08),
      _kBg.withValues(alpha: 0.0),
    );
  }

  void _drawOrb(
    Canvas canvas,
    Offset center,
    double radius,
    Color inner,
    Color outer,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [inner, outer],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

/// Subtle dot grid on light background
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kBlue.withValues(alpha: 0.055);
    const spacing = 44.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

/// Rotating dashed arc ring — light version uses blue/cyan on light bg
class _ArcRingPainter extends CustomPainter {
  _ArcRingPainter(this.entryProgress, {this.isLight = false});
  final double entryProgress;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    if (entryProgress < 0.2) return;
    final opacity = ((entryProgress - 0.2) / 0.4).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Outer arc — sky blue
    _drawDashedArc(
      canvas,
      center,
      radius,
      _kBlueSky.withValues(alpha: 0.5 * opacity),
      strokeWidth: 1.8,
      dashCount: 20,
      gapRatio: 0.4,
    );

    // Inner arc — cyan
    _drawDashedArc(
      canvas,
      center,
      radius - 12,
      _kCyan.withValues(alpha: 0.3 * opacity),
      strokeWidth: 1.2,
      dashCount: 14,
      gapRatio: 0.55,
    );

    // Innermost arc — primary blue dots
    _drawDashedArc(
      canvas,
      center,
      radius - 24,
      _kBlue.withValues(alpha: 0.18 * opacity),
      strokeWidth: 1.0,
      dashCount: 8,
      gapRatio: 0.65,
    );
  }

  void _drawDashedArc(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    required double strokeWidth,
    required int dashCount,
    required double gapRatio,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final total = 2 * math.pi;
    final dashAngle = total / dashCount * (1 - gapRatio);
    final gapAngle = total / dashCount * gapRatio;
    double start = 0;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashAngle,
        false,
        paint,
      );
      start += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) => old.entryProgress != entryProgress;
}

/// Shimmer sweep over logo
class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final sweepX = -size.width + t * size.width * 2.8;
    final rect = Rect.fromLTWH(sweepX - 40, 0, 80, size.height);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0, 0.5, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect)
        ..blendMode = BlendMode.overlay,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.t != t;
}
