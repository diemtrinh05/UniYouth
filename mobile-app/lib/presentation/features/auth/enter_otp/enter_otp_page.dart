import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/app_error.dart';
import '../../../../../core/error/error_presenter.dart';
import '../../../app/providers/app_provider_graph.dart';
import '../../../app/router/app_routes.dart';
import '../state/password_reset_otp_flow_provider.dart';

class EnterOtpPage extends ConsumerStatefulWidget {
  const EnterOtpPage({super.key});

  @override
  ConsumerState<EnterOtpPage> createState() => _EnterOtpPageState();
}

class _EnterOtpPageState extends ConsumerState<EnterOtpPage>
    with SingleTickerProviderStateMixin {
  static const int _otpExpiresInSeconds = 5 * 60;
  static const int _resendCooldownInSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _ticker;
  int _otpRemainingSeconds = _otpExpiresInSeconds;
  int _resendRemainingSeconds = _resendCooldownInSeconds;
  bool _hasScheduledGuardRedirect = false;

  bool get _canResend => _resendRemainingSeconds <= 0;
  bool get _otpExpired => _otpRemainingSeconds <= 0;

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
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _syncTimersFromFlowState();
    _startTicker();
    _animController.forward();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _otpController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _syncTimersFromFlowState();
    });
  }

  void _syncTimersFromFlowState() {
    final flowState = ref.read(passwordResetOtpFlowNotifierProvider);
    final flowNotifier = ref.read(
      passwordResetOtpFlowNotifierProvider.notifier,
    );

    if (!flowState.hasEmail) {
      return;
    }

    final now = DateTime.now();
    final otpExpiresAt =
        flowState.otpExpiresAt ?? now.add(const Duration(minutes: 5));
    final resendAvailableAt =
        flowState.resendAvailableAt ?? now.add(const Duration(seconds: 30));

    if (flowState.otpExpiresAt == null || flowState.resendAvailableAt == null) {
      flowNotifier.setOtpTiming(
        otpExpiresAt: otpExpiresAt,
        resendAvailableAt: resendAvailableAt,
      );
    }

    final nextOtpRemaining = _secondsUntil(otpExpiresAt);
    final nextResendRemaining = _secondsUntil(resendAvailableAt);

    if (!mounted) {
      _otpRemainingSeconds = nextOtpRemaining;
      _resendRemainingSeconds = nextResendRemaining;
      return;
    }

    setState(() {
      _otpRemainingSeconds = nextOtpRemaining;
      _resendRemainingSeconds = nextResendRemaining;
    });
  }

  int _secondsUntil(DateTime target) {
    final difference = target.difference(DateTime.now()).inSeconds;
    return difference < 0 ? 0 : difference;
  }

  Future<void> _submit() async {
    final flowState = ref.read(passwordResetOtpFlowNotifierProvider);
    if (!flowState.hasEmail) {
      _redirectToForgotPassword();
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || flowState.isSubmittingVerify || _otpRemainingSeconds <= 0) {
      return;
    }

    final flowNotifier = ref.read(
      passwordResetOtpFlowNotifierProvider.notifier,
    );
    flowNotifier.markVerifySubmitting(true);

    try {
      final result = await ref.read(verifyResetOtpUseCaseProvider)(
        account: flowState.email!,
        otpCode: _otpController.text.trim(),
      );

      _otpController.clear();
      flowNotifier.setVerificationResult(
        message: result.message,
        verificationTicket: result.verificationTicket,
        verificationTicketExpiresAt: result.expiresAt,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamed(AppRoutes.resetPassword);
    } on AppError catch (error) {
      final presented = ErrorPresenter.presentAppError(
        error,
        operation: 'xác thực OTP',
      );
      flowNotifier.setError(presented.message);
    } finally {
      flowNotifier.markVerifySubmitting(false);
    }
  }

  Future<void> _handleResend() async {
    final flowState = ref.read(passwordResetOtpFlowNotifierProvider);
    if (!_canResend || !flowState.hasEmail || flowState.isSubmittingForgot) {
      return;
    }

    final flowNotifier = ref.read(
      passwordResetOtpFlowNotifierProvider.notifier,
    );
    flowNotifier.markForgotSubmitting(true);

    try {
      final message = await ref.read(forgotPasswordUseCaseProvider)(
        account: flowState.email!,
      );
      final now = DateTime.now();

      _otpController.clear();
      flowNotifier.beginOtpStep(
        email: flowState.email!,
        otpExpiresAt: now.add(const Duration(minutes: 5)),
        resendAvailableAt: now.add(const Duration(seconds: 30)),
        message: message,
      );
      _syncTimersFromFlowState();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on AppError catch (error) {
      final presented = ErrorPresenter.presentAppError(
        error,
        operation: 'gửi lại mã OTP',
      );
      flowNotifier.setError(presented.message);
    } finally {
      flowNotifier.markForgotSubmitting(false);
    }
  }

  void _handleBack() {
    ref
        .read(passwordResetOtpFlowNotifierProvider.notifier)
        .backToEnterEmail(preserveEmail: true);
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

  String _formatSeconds(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _resendButtonLabel() {
    if (_otpExpired && _canResend) {
      return 'Gửi lại mã OTP mới';
    }
    if (_otpExpired) {
      return 'OTP đã hết hạn, gửi lại sau ${_resendRemainingSeconds}s';
    }
    if (_canResend) {
      return 'Gửi lại mã';
    }
    return 'Gửi lại mã sau ${_resendRemainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(passwordResetOtpFlowNotifierProvider);
    if (!flowState.hasEmail) {
      _redirectToForgotPassword();
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final otpExpired = _otpExpired;

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
            right: 12,
            child: Container(
              width: 70,
              height: 70,
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
                              Icons.mark_email_read_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'Nhập mã OTP',
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
                          'Nhập mã gồm 6 chữ số đã được gửi tới email đã liên kết với tài khoản ${flowState.email}.',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: otpExpired
                                ? const Color(0xFFFFF1F2)
                                : const Color(0xFFEEF4FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: otpExpired
                                  ? const Color(
                                      0xFFE53935,
                                    ).withValues(alpha: 0.2)
                                  : const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                otpExpired
                                    ? Icons.error_outline_rounded
                                    : Icons.timer_outlined,
                                color: otpExpired
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF3B82F6),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  otpExpired
                                      ? 'Mã OTP đã hết hạn. Bạn có thể gửi lại mã mới.'
                                      : 'Mã OTP hết hạn sau ${_formatSeconds(_otpRemainingSeconds)}',
                                  style: TextStyle(
                                    color: otpExpired
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFF1D4ED8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Mã OTP'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: 10,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: '123456',
                            counterText: '',
                            hintStyle: TextStyle(
                              color: const Color(
                                0xFF0F172A,
                              ).withValues(alpha: 0.25),
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 10,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 12,
                              ),
                              child: Icon(
                                Icons.password_rounded,
                                color: const Color(0xFF3B82F6),
                                size: 20,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.15),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF3B82F6),
                                width: 1.8,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE53935),
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE53935),
                                width: 1.8,
                              ),
                            ),
                            errorStyle: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          validator: (value) {
                            final otp = value?.trim() ?? '';
                            if (otp.isEmpty) {
                              return 'Vui lòng nhập mã OTP';
                            }
                            if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                              return 'OTP phải gồm đúng 6 chữ số';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Chỉ nhập chữ số. Không lưu OTP lâu dài trên thiết bị.',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.48),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        if (otpExpired) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4E5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Mã OTP này không còn hiệu lực. Hãy gửi lại mã mới để tiếp tục đặt lại mật khẩu.',
                                    style: TextStyle(
                                      color: Color(0xFFB45309),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (flowState.errorMessage != null)
                          _FeedbackBanner(
                            message: flowState.errorMessage!,
                            isError: true,
                          ),
                        if (flowState.message != null &&
                            (flowState.errorMessage == null ||
                                flowState.message != flowState.errorMessage))
                          _FeedbackBanner(
                            message: flowState.message!,
                            isError: false,
                          ),
                        if (flowState.errorMessage != null ||
                            flowState.message != null)
                          const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                flowState.isSubmittingVerify || otpExpired
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
                                gradient: flowState.isSubmittingVerify
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
                                boxShadow: flowState.isSubmittingVerify
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF8B5CF6,
                                          ).withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: flowState.isSubmittingVerify
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
                                        'Xác thực OTP',
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
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton(
                            onPressed:
                                _canResend && !flowState.isSubmittingForgot
                                ? _handleResend
                                : null,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              _resendButtonLabel(),
                              style: TextStyle(
                                color:
                                    _canResend && !flowState.isSubmittingForgot
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF94A3B8),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFEDED) : const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? const Color(0xFFFF4444).withValues(alpha: 0.3)
              : const Color(0xFF3B82F6).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: isError ? const Color(0xFFE53935) : const Color(0xFF1D4ED8),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? const Color(0xFFE53935)
                    : const Color(0xFF1D4ED8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
