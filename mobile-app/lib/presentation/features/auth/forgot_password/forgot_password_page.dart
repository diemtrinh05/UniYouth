import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../../app/router/app_routes.dart';
import '../state/password_recovery_provider.dart';
import '../state/password_reset_otp_flow_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, required this.forgotPasswordUseCase});

  final ForgotPasswordUseCase forgotPasswordUseCase;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final existingAccount = ref.read(passwordResetOtpFlowNotifierProvider).email;
    if (existingAccount != null && existingAccount.trim().isNotEmpty) {
      _accountController.text = existingAccount.trim();
    }

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
    _accountController.dispose();
    _animController.dispose();
    super.dispose();
  }

  ForgotPasswordNotifierDependencies get _forgotPasswordDependencies =>
      ForgotPasswordNotifierDependencies(
        forgotPasswordUseCase: widget.forgotPasswordUseCase,
      );

  Future<void> _submit() async {
    final notifierProvider = forgotPasswordNotifierByDependenciesProvider(
      _forgotPasswordDependencies,
    );
    final state = ref.read(notifierProvider);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || state.isSubmitting) {
      return;
    }

    await ref
        .read(notifierProvider.notifier)
        .submit(account: _accountController.text);

    if (!mounted) {
      return;
    }

    final nextState = ref.read(notifierProvider);
    if (!nextState.isSuccess) {
      return;
    }

    final now = DateTime.now();
    ref
        .read(passwordResetOtpFlowNotifierProvider.notifier)
        .beginOtpStep(
          email: _accountController.text,
          otpExpiresAt: now.add(const Duration(minutes: 5)),
          resendAvailableAt: now.add(const Duration(seconds: 30)),
          message: nextState.message,
        );

    final message = nextState.message?.trim();
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    Navigator.of(context).pushNamed(AppRoutes.enterOtp);
  }

  @override
  Widget build(BuildContext context) {
    final forgotPasswordState = ref.watch(
      forgotPasswordNotifierByDependenciesProvider(_forgotPasswordDependencies),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.login),
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
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 10,
            child: Container(
              width: 70,
              height: 70,
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
                        const SizedBox(height: 32),
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'Quên mật khẩu?',
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
                          'Nhập tài khoản để nhận mã OTP đặt lại mật khẩu qua email đã đăng ký.',
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
                        _buildLabel('Tài khoản'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _accountController,
                          hintText: 'Nhập mã sinh viên hoặc tài khoản',
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (value) {
                            final account = value?.trim() ?? '';
                            if (account.isEmpty) {
                              return 'Vui lòng nhập tài khoản';
                            }
                            if (account.length > 50) {
                              return 'Tài khoản tối đa 50 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hệ thống sẽ gửi OTP về email đã liên kết với tài khoản này.',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.48),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (forgotPasswordState.message != null &&
                            !forgotPasswordState.isSuccess)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
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
                                    forgotPasswordState.message!,
                                    style: const TextStyle(
                                      color: Color(0xFFE53935),
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
                            onPressed: forgotPasswordState.isSubmitting
                                ? null
                                : _submit,
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
                                gradient: forgotPasswordState.isSubmitting
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
                                boxShadow: forgotPasswordState.isSubmitting
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
                                child: forgotPasswordState.isSubmitting
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
                                        'Gửi mã OTP',
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
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
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
