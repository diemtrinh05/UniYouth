import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/usecases/auth/reset_password_usecase.dart';
import '../../../app/router/app_routes.dart';
import '../state/password_recovery_provider.dart';
import '../state/password_reset_otp_flow_provider.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.resetPasswordUseCase});

  final ResetPasswordUseCase resetPasswordUseCase;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _obscureConfirmPassword = true;
  bool _hasScheduledGuardRedirect = false;
  bool _isRecoveringToEnterOtp = false;
  bool _isCompletingToLogin = false;

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
    _animController.forward();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  ResetPasswordNotifierDependencies get _resetPasswordDependencies =>
      ResetPasswordNotifierDependencies(
        resetPasswordUseCase: widget.resetPasswordUseCase,
      );

  Future<void> _submit({required String verificationTicket}) async {
    final flowNotifier = ref.read(
      passwordResetOtpFlowNotifierProvider.notifier,
    );
    final state = ref.read(
      resetPasswordNotifierByDependenciesProvider(_resetPasswordDependencies),
    );
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || state.isSubmitting) {
      return;
    }

    flowNotifier.markResetSubmitting(true);
    await ref
        .read(
          resetPasswordNotifierByDependenciesProvider(
            _resetPasswordDependencies,
          ).notifier,
        )
        .submit(
          verificationTicket: verificationTicket,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    final nextState = ref.read(
      resetPasswordNotifierByDependenciesProvider(_resetPasswordDependencies),
    );
    if (!nextState.isSuccess) {
      flowNotifier.markResetSubmitting(false);
      if (nextState.requiresVerificationTicketRecovery) {
        _recoverToEnterOtp(message: nextState.message);
      }
      return;
    }

    final message = nextState.message?.trim();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _isCompletingToLogin = true;
    flowNotifier.completeFlow(message: message);
    flowNotifier.clearFlow();

    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  void _recoverToEnterOtp({String? message}) {
    if (_isRecoveringToEnterOtp || !mounted) {
      return;
    }

    _isRecoveringToEnterOtp = true;
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    ref
        .read(passwordResetOtpFlowNotifierProvider.notifier)
        .recoverFromInvalidVerificationTicket(message: message);
    Navigator.of(context).pop();
  }

  void _redirectToForgotPassword() {
    if (_hasScheduledGuardRedirect) {
      return;
    }
    _hasScheduledGuardRedirect = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.forgotPassword);
    });
  }

  void _handleBack() {
    ref.read(passwordResetOtpFlowNotifierProvider.notifier).backToEnterOtp();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final otpFlowState = ref.watch(passwordResetOtpFlowNotifierProvider);
    if (!otpFlowState.hasVerificationTicket) {
      if (!_isRecoveringToEnterOtp && !_isCompletingToLogin) {
        _redirectToForgotPassword();
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final verificationTicket = otpFlowState.verificationTicket!.trim();
    final resetPasswordState = ref.watch(
      resetPasswordNotifierByDependenciesProvider(_resetPasswordDependencies),
    );
    final resetPasswordNotifier = ref.read(
      resetPasswordNotifierByDependenciesProvider(
        _resetPasswordDependencies,
      ).notifier,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: _handleBack,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
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
                        const SizedBox(height: 32),
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'Đặt lại\nmật khẩu',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nhập mật khẩu mới cho tài khoản của bạn. Mã xác thực đã được xử lý ở bước trước.',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 44),
                        _buildLabel('Mật khẩu mới'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _newPasswordController,
                          hintText: 'Tối thiểu 8 ký tự',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: resetPasswordState.obscurePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            icon: Icon(
                              resetPasswordState.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFBBA0E0),
                              size: 20,
                            ),
                            onPressed:
                                resetPasswordNotifier.toggleObscurePassword,
                          ),
                          validator: (value) {
                            final password = value?.trim() ?? '';
                            if (password.isEmpty) {
                              return 'Vui lòng nhập mật khẩu mới';
                            }
                            if (password.length < 8) {
                              return 'Mật khẩu tối thiểu 8 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Xác nhận mật khẩu mới'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Nhập lại mật khẩu mới',
                          prefixIcon: Icons.lock_reset_rounded,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              _submit(verificationTicket: verificationTicket),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFFBBA0E0),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            final confirmPassword = value?.trim() ?? '';
                            if (confirmPassword.isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu mới';
                            }
                            if (confirmPassword !=
                                _newPasswordController.text.trim()) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Mật khẩu nên có chữ hoa, số và ký tự đặc biệt để bảo mật hơn.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (otpFlowState.message != null &&
                            !resetPasswordState.isSubmitting &&
                            (resetPasswordState.message == null ||
                                resetPasswordState.message !=
                                    otpFlowState.message))
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF4FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF1D4ED8),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    otpFlowState.message!,
                                    style: const TextStyle(
                                      color: Color(0xFF1D4ED8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (resetPasswordState.message != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: resetPasswordState.isSuccess
                                  ? const Color(0xFFEDFDF5)
                                  : const Color(0xFFFFEDED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: resetPasswordState.isSuccess
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3)
                                    : const Color(
                                        0xFFFF4444,
                                      ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  resetPasswordState.isSuccess
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.error_outline_rounded,
                                  color: resetPasswordState.isSuccess
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFE53935),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    resetPasswordState.message!,
                                    style: TextStyle(
                                      color: resetPasswordState.isSuccess
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFFE53935),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: resetPasswordState.isSubmitting
                                ? null
                                : () => _submit(
                                    verificationTicket: verificationTicket,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: resetPasswordState.isSubmitting
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
                                          Color(0xFF8B5CF6),
                                          Color(0xFF3B82F6),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: resetPasswordState.isSubmitting
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF8B5CF6,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: resetPasswordState.isSubmitting
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
                                    : const Text(
                                        'Đặt lại mật khẩu',
                                        style: TextStyle(
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
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.login);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Nhớ mật khẩu rồi? ',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Đăng nhập',
                                    style: TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
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
