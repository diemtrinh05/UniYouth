import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/usecases/profile/change_password_usecase.dart';
import 'state/change_password_notifier.dart';
import 'state/change_password_provider.dart';
import 'state/change_password_state.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueDark = Color(0xFF0D47A1);
const _kBlueMid = Color(0xFF1976D2);
const _kBlueLight = Color(0xFFE3F2FD);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);
const _kError = Color(0xFFC62828);
const _kSuccess = Color(0xFF2E7D32);

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key, required this.changePasswordUseCase});

  final ChangePasswordUseCase changePasswordUseCase;

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  late final ChangePasswordNotifierDependencies _changePasswordDependencies;
  late final StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>
  _changePasswordStateProvider;

  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(
      parent: _successCtrl,
      curve: Curves.elasticOut,
    );

    _changePasswordDependencies = ChangePasswordNotifierDependencies(
      changePasswordUseCase: widget.changePasswordUseCase,
    );
    _changePasswordStateProvider = changePasswordNotifierByDependenciesProvider(
      _changePasswordDependencies,
    );

    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    _currentPasswordController.dispose();
    _newPasswordController
      ..removeListener(_onNewPasswordChanged)
      ..dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged() {
    ref
        .read(_changePasswordStateProvider.notifier)
        .updatePasswordStrength(_newPasswordController.text);
  }

  String? _validateCurrentPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final pw = value ?? '';
    if (pw.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (pw.length < 8) {
      return 'Mật khẩu tối thiểu 8 ký tự';
    }
    if (pw.length > 100) {
      return 'Mật khẩu tối đa 100 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới';
    }
    if (value != _newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final didSucceed = await ref
        .read(_changePasswordStateProvider.notifier)
        .submit(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmNewPassword: _confirmNewPasswordController.text,
        );

    if (didSucceed) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    }
  }

  Color _strengthColor(int strength) {
    switch (strength) {
      case 1:
        return const Color(0xFFC62828);
      case 2:
        return const Color(0xFFE65100);
      case 3:
        return const Color(0xFFF9A825);
      case 4:
        return _kSuccess;
      default:
        return _kBlueLight;
    }
  }

  String _strengthLabel(int strength) {
    switch (strength) {
      case 1:
        return 'Yếu';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Khá mạnh';
      case 4:
        return 'Mạnh';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChangePasswordState>(_changePasswordStateProvider, (
      previous,
      next,
    ) {
      if (next.isSuccess && previous?.isSuccess != true) {
        _successCtrl.forward(from: 0);
      }
    });
    ref.watch(
      _changePasswordStateProvider.select(
        (state) => (
          state.isSubmitting,
          state.obscureCurrent,
          state.obscureNew,
          state.obscureConfirm,
          state.message,
          state.isSuccess,
          state.currentPasswordBackendError,
          state.newPasswordBackendError,
          state.confirmNewPasswordBackendError,
          state.passwordStrength,
        ),
      ),
    );
    final state = ref.read(_changePasswordStateProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: _kTextDark,
            elevation: 0,
            title: const Text(
              'Đổi mật khẩu',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: _kTextDark,
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                const expandedHeight = 160.0;
                final topPadding = MediaQuery.of(context).padding.top;
                final collapsedHeight = topPadding + kToolbarHeight;
                final t =
                    ((constraints.maxHeight - collapsedHeight) /
                            (expandedHeight - collapsedHeight))
                        .clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kBlueDark, _kBlueMid],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Opacity(
                            opacity: t,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Đổi mật khẩu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bảo mật tài khoản của bạn',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.isSuccess && state.message != null)
                      ScaleTransition(
                        scale: _successScale,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _kSuccess.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _kSuccess.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _kSuccess.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: _kSuccess,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Thành công!',
                                      style: TextStyle(
                                        color: _kSuccess,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      state.message!,
                                      style: const TextStyle(
                                        color: _kSuccess,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _kBlueLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: _kBlue,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mật khẩu nên có ít nhất 8 ký tự, bao gồm chữ hoa, số và ký tự đặc biệt.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kBlue,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _FormCard(
                      children: [
                        _PasswordField(
                          controller: _currentPasswordController,
                          label: 'Mật khẩu hiện tại',
                          icon: Icons.lock_outline_rounded,
                          obscureText: state.obscureCurrent,
                          onToggle: () => ref
                              .read(_changePasswordStateProvider.notifier)
                              .toggleCurrentVisibility(),
                          validator: _validateCurrentPassword,
                          backendErrorText: state.currentPasswordBackendError,
                          onChanged: (_) {
                            if (state.currentPasswordBackendError == null) {
                              return;
                            }
                            ref
                                .read(_changePasswordStateProvider.notifier)
                                .clearBackendError(
                                  ChangePasswordBackendField.currentPassword,
                                );
                          },
                        ),
                        const _FieldDivider(),
                        _PasswordField(
                          controller: _newPasswordController,
                          label: 'Mật khẩu mới',
                          icon: Icons.lock_reset_rounded,
                          obscureText: state.obscureNew,
                          onToggle: () => ref
                              .read(_changePasswordStateProvider.notifier)
                              .toggleNewVisibility(),
                          validator: _validateNewPassword,
                          backendErrorText: state.newPasswordBackendError,
                          onChanged: (_) {
                            if (state.newPasswordBackendError == null) {
                              return;
                            }
                            ref
                                .read(_changePasswordStateProvider.notifier)
                                .clearBackendError(
                                  ChangePasswordBackendField.newPassword,
                                );
                          },
                        ),
                        if (_newPasswordController.text.isNotEmpty)
                          _PasswordStrengthBar(
                            strength: state.passwordStrength,
                            color: _strengthColor(state.passwordStrength),
                            label: _strengthLabel(state.passwordStrength),
                          ),
                        const _FieldDivider(),
                        _PasswordField(
                          controller: _confirmNewPasswordController,
                          label: 'Xác nhận mật khẩu mới',
                          icon: Icons.verified_user_rounded,
                          obscureText: state.obscureConfirm,
                          onToggle: () => ref
                              .read(_changePasswordStateProvider.notifier)
                              .toggleConfirmVisibility(),
                          validator: _validateConfirmPassword,
                          backendErrorText:
                              state.confirmNewPasswordBackendError,
                          onChanged: (_) {
                            if (state.confirmNewPasswordBackendError == null) {
                              return;
                            }
                            ref
                                .read(_changePasswordStateProvider.notifier)
                                .clearBackendError(
                                  ChangePasswordBackendField.confirmNewPassword,
                                );
                          },
                        ),
                      ],
                    ),

                    if (!state.isSuccess && state.message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kError.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _kError.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: _kError,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.message!,
                                style: const TextStyle(
                                  color: _kError,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: state.isSubmitting ? null : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: state.isSubmitting
                              ? null
                              : const LinearGradient(
                                  colors: [_kBlueDark, _kBlueMid],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: state.isSubmitting ? _kBlueLight : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: state.isSubmitting
                              ? null
                              : [
                                  BoxShadow(
                                    color: _kBlue.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: state.isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _kBlue,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Đổi mật khẩu',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: _kBlueLight,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.obscureText,
    required this.onToggle,
    required this.validator,
    this.backendErrorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;
  final String? backendErrorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: _kTextDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _kTextMid),
          prefixIcon: Icon(icon, size: 19, color: _kBlue),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19,
              color: _kTextMid,
            ),
          ),
          errorText: backendErrorText,
          border: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11, color: _kError),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({
    required this.strength,
    required this.color,
    required this.label,
  });
  final int strength;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final filled = i < strength;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: filled ? color : _kBlueLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Độ mạnh: $label',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
