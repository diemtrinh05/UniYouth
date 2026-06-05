import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../../../core/network/retry_policy/rate_limit_policy.dart';
import '../../../../domain/usecases/auth/login_usecase.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/mappers/notification_error_ui_mapper.dart';
import '../state/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    super.key,
    required this.loginUseCase,
    required this.onAuthenticatedTokenSync,
    required this.consumeNotificationPermissionDeniedHint,
    this.onPendingPostLoginNavigation,
  });

  final LoginUseCase loginUseCase;
  final Future<bool> Function() onAuthenticatedTokenSync;
  final bool Function() consumeNotificationPermissionDeniedHint;
  final Future<bool> Function(NavigatorState navigator)?
  onPendingPostLoginNavigation;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late AuthNotifierDependencies _authDependencies;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _syncAuthDependencies();
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loginUseCase != widget.loginUseCase ||
        oldWidget.onAuthenticatedTokenSync != widget.onAuthenticatedTokenSync ||
        oldWidget.consumeNotificationPermissionDeniedHint !=
            widget.consumeNotificationPermissionDeniedHint) {
      _syncAuthDependencies();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _syncAuthDependencies() {
    _authDependencies = AuthNotifierDependencies(
      loginUseCase: widget.loginUseCase,
      onAuthenticatedTokenSync: widget.onAuthenticatedTokenSync,
      consumeNotificationPermissionDeniedHint:
          widget.consumeNotificationPermissionDeniedHint,
    );
  }

  Future<void> _submit() async {
    final authState = ref.read(
      authNotifierByDependenciesProvider(_authDependencies),
    );
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || authState.isSubmitting || authState.isLoginRateLimited) {
      return;
    }

    final notifier = ref.read(
      authNotifierByDependenciesProvider(_authDependencies).notifier,
    );
    await notifier.submitLogin(
      code: _codeController.text,
      password: _passwordController.text,
      onAuthenticatedTokenSync: widget.onAuthenticatedTokenSync,
      consumeNotificationPermissionDeniedHint:
          widget.consumeNotificationPermissionDeniedHint,
    );

    if (!mounted) {
      return;
    }

    final nextState = ref.read(
      authNotifierByDependenciesProvider(_authDependencies),
    );
    if (nextState.handledInitialNotificationNavigation) {
      return;
    }

    if (nextState.shouldPromptNotificationPermissionSettings) {
      await _showNotificationPermissionSettingsPrompt();
      if (!mounted) {
        return;
      }
      notifier.consumeNotificationPermissionPromptSignal();
    }

    final handledPendingPostLoginNavigation =
        await widget.onPendingPostLoginNavigation?.call(
          Navigator.of(context),
        ) ??
        false;
    if (handledPendingPostLoginNavigation || !mounted) {
      return;
    }

    final currentState = ref.read(
      authNotifierByDependenciesProvider(_authDependencies),
    );
    if (currentState.shouldNavigateToHome) {
      notifier.consumeNavigateToHomeSignal();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.app);
    }
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
    final authState = ref.watch(
      authNotifierByDependenciesProvider(_authDependencies),
    );
    final authNotifier = ref.read(
      authNotifierByDependenciesProvider(_authDependencies).notifier,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),

                        // Logo + App name
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                size: 26,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'UniYouth',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 52),

                        // Heading
                        const Text(
                          'Chào mừng\ntrở lại! 👋',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Đăng nhập để tiếp tục hành trình học tập.',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 44),

                        // Code field
                        _buildLabel('Mã sinh viên'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _codeController,
                          hintText: 'Nhập mã sinh viên của bạn',
                          prefixIcon: Icons.badge_outlined,
                          textInputAction: TextInputAction.next,
                          backendErrorText: authState.codeBackendError,
                          onChanged: (_) {
                            authNotifier.clearCodeBackendError();
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mã sinh viên';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Password field
                        _buildLabel('Mật khẩu'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Nhập mật khẩu của bạn',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: authState.obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          backendErrorText: authState.passwordBackendError,
                          onChanged: (_) {
                            authNotifier.clearPasswordBackendError();
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              authState.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFBBA080),
                              size: 20,
                            ),
                            onPressed: authNotifier.toggleObscurePassword,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            return null;
                          },
                        ),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.forgotPassword);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Error message
                        if (authState.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFFFF4444,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFE53935),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                (authState.isSubmitting ||
                                    authState.isLoginRateLimited)
                                ? null
                                : _submit,
                            style:
                                ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.zero,
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.all(
                                    Colors.transparent,
                                  ),
                                ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: authState.isSubmitting
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFCCCCCC),
                                          Color(0xFFCCCCCC),
                                        ],
                                      )
                                    : const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF8B5CF6),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: authState.isSubmitting
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF3B82F6,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: authState.isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        authState.isLoginRateLimited
                                            ? RateLimitPolicy.retryLabel(
                                                seconds: authState
                                                    .loginCooldownSeconds,
                                              )
                                            : 'Đăng nhập',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    String? backendErrorText,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        errorText: backendErrorText,
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF0F172A).withValues(alpha: 0.3),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(prefixIcon, color: const Color(0xFF3B82F6), size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF0F172A).withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.8),
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFFE53935),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}



