import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/usecases/profile/delete_avatar_usecase.dart';
import '../../../../../domain/usecases/profile/enroll_face_profile_usecase.dart';
import '../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../../../domain/usecases/profile/request_face_profile_reauth_otp_usecase.dart';
import '../../../../../domain/usecases/profile/upload_avatar_usecase.dart';
import '../../attendance/face_capture/attendance_face_capture_service.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/error_widgets/app_error_snackbar.dart';
import '../../../shared/error_widgets/app_error_view.dart';
import '../avatar/avatar_picker_service.dart';
import 'state/profile_view_notifier.dart';
import 'state/profile_view_provider.dart';
import 'state/profile_view_state.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueDark = Color(0xFF0D47A1);
const _kBlueMid = Color(0xFF1976D2);
const _kCyan = Color(0xFF00BCD4);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);

class ProfileViewPage extends ConsumerStatefulWidget {
  const ProfileViewPage({
    super.key,
    required this.getMyProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.deleteAvatarUseCase,
    required this.enrollFaceProfileUseCase,
    required this.requestFaceProfileReauthOtpUseCase,
    required this.avatarPickerService,
    required this.faceCaptureService,
  });

  final GetMyProfileUseCase getMyProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final DeleteAvatarUseCase deleteAvatarUseCase;
  final EnrollFaceProfileUseCase enrollFaceProfileUseCase;
  final RequestFaceProfileReauthOtpUseCase requestFaceProfileReauthOtpUseCase;
  final AvatarPickerService avatarPickerService;
  final AttendanceFaceCaptureService faceCaptureService;

  @override
  ConsumerState<ProfileViewPage> createState() => _ProfileViewPageState();
}

class _ProfileViewPageState extends ConsumerState<ProfileViewPage> {
  late final ProfileViewNotifierDependencies _profileDependencies;
  late final StateNotifierProvider<ProfileViewNotifier, ProfileViewState>
  _profileViewStateProvider;
  bool _isStartingFaceEnrollment = false;

  @override
  void initState() {
    super.initState();
    _profileDependencies = ProfileViewNotifierDependencies(
      getMyProfileUseCase: widget.getMyProfileUseCase,
      uploadAvatarUseCase: widget.uploadAvatarUseCase,
      deleteAvatarUseCase: widget.deleteAvatarUseCase,
      enrollFaceProfileUseCase: widget.enrollFaceProfileUseCase,
      requestFaceProfileReauthOtpUseCase: widget.requestFaceProfileReauthOtpUseCase,
      avatarPickerService: widget.avatarPickerService,
      faceCaptureService: widget.faceCaptureService,
    );
    _profileViewStateProvider = profileViewNotifierByDependenciesProvider(
      _profileDependencies,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadProfile());
    });
  }

  Future<void> _loadProfile() =>
      ref.read(_profileViewStateProvider.notifier).syncInitial();

  Future<void> _openEditProfile(MyProfile profile) async {
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.profileEdit, arguments: profile);
    if (!mounted) {
      return;
    }
    if (result == true) {
      await _loadProfile();
    }
  }

  Future<void> _uploadAvatar() =>
      ref.read(_profileViewStateProvider.notifier).uploadAvatar();

  Future<void> _deleteAvatar() =>
      ref.read(_profileViewStateProvider.notifier).deleteAvatar();

  Future<void> _enrollFace() async {
    if (_isStartingFaceEnrollment) {
      return;
    }

    setState(() {
      _isStartingFaceEnrollment = true;
    });

    final profile = ref.read(_profileViewStateProvider).profile;
    String? reauthOtpCode;
    try {
      if (profile?.hasActiveFaceProfile == true) {
        final otpRequested = await ref
            .read(_profileViewStateProvider.notifier)
            .requestFaceProfileReauthOtp();
        if (!mounted || !otpRequested) {
          return;
        }

        reauthOtpCode = await _promptReauthOtpForFaceReplacement();
        if (!mounted || reauthOtpCode == null) {
          return;
        }
      }

      final evidence = await widget.faceCaptureService.captureFaceEvidence(
        context,
        flowMode: FaceCaptureFlowMode.enroll,
      );
      if (!mounted || evidence == null) {
        return;
      }

      await ref
          .read(_profileViewStateProvider.notifier)
          .enrollFaceProfile(
            faceImage: evidence.faceImage,
            reauthOtpCode: reauthOtpCode,
          );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingFaceEnrollment = false;
        });
      }
    }
  }

  Future<String?> _promptReauthOtpForFaceReplacement() {
    final otpController = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: const [
              Icon(Icons.verified_user_rounded, color: _kBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Xác nhận cập nhật khuôn mặt',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mã OTP xác nhận đã được gửi tới email của tài khoản này. Nhập mã OTP để tiếp tục cập nhật khuôn mặt. Ảnh mới cũng phải khớp với khuôn mặt đang đăng ký.',
                style: TextStyle(height: 1.5, color: Color(0xFF455A64)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: otpController,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Mã OTP',
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) {
                  final otpCode = otpController.text.trim();
                  if (otpCode.isEmpty) {
                    setDialogState(
                      () => errorText = 'Vui lòng nhập mã OTP.',
                    );
                    return;
                  }
                  if (otpCode.length != 6) {
                    setDialogState(
                      () => errorText = 'Mã OTP phải gồm đúng 6 chữ số.',
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(otpCode);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final otpCode = otpController.text.trim();
                if (otpCode.isEmpty) {
                  setDialogState(
                    () => errorText = 'Vui lòng nhập mã OTP.',
                  );
                  return;
                }
                if (otpCode.length != 6) {
                  setDialogState(
                    () => errorText = 'Mã OTP phải gồm đúng 6 chữ số.',
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(otpCode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) =>
      AppErrorSnackBar.show(context, message: message);

  String _safeText(String? value) {
    final n = value?.trim();
    return (n == null || n.isEmpty) ? 'Không có' : n;
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Không có';
    }
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Không có';
    }
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileViewState>(_profileViewStateProvider, (previous, next) {
      final feedbackMessage = next.feedbackMessage;
      if (feedbackMessage == null) {
        return;
      }
      _showSnackBar(feedbackMessage);
      ref.read(_profileViewStateProvider.notifier).clearFeedbackMessage();
    });

    final state = ref.watch(_profileViewStateProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ProfileViewState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }

    if (state.errorMessage != null) {
      return AppErrorView(
        title: 'Không thể tải hồ sơ cá nhân',
        message: state.errorMessage!,
        onRetry: _loadProfile,
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return RefreshIndicator(
        onRefresh: _loadProfile,
        color: _kBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Center(child: Text('Không có dữ liệu hồ sơ')),
          ],
        ),
      );
    }

    final avatarUrl = (profile.avatarUrl ?? '').trim();
    final hasAvatar = avatarUrl.isNotEmpty;
    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: _kBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kBlueDark, _kBlueMid, Color(0xFF0288D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: hasAvatar
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _emptyAvatar(),
                              )
                            : _emptyAvatar(),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: state.isUploadingAvatar ? null : _uploadAvatar,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: _kCyan,
                            shape: BoxShape.circle,
                          ),
                          child: state.isUploadingAvatar
                              ? const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _safeText(profile.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã: ${_safeText(profile.code)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      if ((profile.role ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            profile.role!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Chỉnh sửa',
                    color: _kBlue,
                    onTap: () => _openEditProfile(profile),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.lock_rounded,
                    label: 'Đổi mật khẩu',
                    color: const Color(0xFF00695C),
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.profileChangePassword),
                  ),
                ),
                if (hasAvatar) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Xóa ảnh',
                      color: const Color(0xFFC62828),
                      onTap: state.isDeletingAvatar ? null : _deleteAvatar,
                      isLoading: state.isDeletingAvatar,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural_rounded,
                        color: _kBlue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Khuôn mặt đăng ký',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _kTextDark,
                        ),
                      ),
                    ),
                    _FaceStatusChip(
                      hasFaceProfile: profile.hasActiveFaceProfile,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildFaceProfileSummaryIcon(
                      hasFaceProfile: profile.hasActiveFaceProfile,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.hasActiveFaceProfile
                                ? 'Đã sẵn sàng xác minh khuôn mặt'
                                : 'Chưa có hồ sơ khuôn mặt hoạt động',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _kTextDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildFaceMetaRow(
                            icon: Icons.schedule_rounded,
                            label: 'Cập nhật gần nhất',
                            value: _formatDateTime(
                              profile.faceProfileUpdatedDate,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildFaceMetaRow(
                            icon: Icons.analytics_rounded,
                            label: 'Chất lượng hồ sơ khuôn mặt',
                            value: profile.faceProfileQualityScore == null
                                ? 'Không có'
                                : '%',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        (state.isEnrollingFace || _isStartingFaceEnrollment)
                        ? null
                        : _enrollFace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: (state.isEnrollingFace || _isStartingFaceEnrollment)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt_rounded),
                    label: Text(
                      profile.hasActiveFaceProfile
                          ? 'Cập nhật khuôn mặt'
                          : 'Đăng ký khuôn mặt',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Thông tin cá nhân',
            icon: Icons.person_rounded,
            rows: [
              _InfoRow('Họ và tên', _safeText(profile.fullName)),
              _InfoRow('Email', _safeText(profile.email)),
              _InfoRow('Số điện thoại', _safeText(profile.phone)),
              _InfoRow(
                'Giới tính',
                profile.gender == null
                    ? 'Không có'
                    : (profile.gender! ? 'Nam' : 'Nữ'),
              ),
              _InfoRow('Ngày sinh', _formatDate(profile.dateOfBirth)),
              _InfoRow('Địa chỉ', _safeText(profile.address)),
            ],
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Thông tin học tập',
            icon: Icons.school_rounded,
            rows: [
              _InfoRow('Mã', _safeText(profile.code)),
              _InfoRow('Đơn vị', _safeText(profile.unitName)),
              _InfoRow('Viện', _safeText(profile.instituteName)),
              _InfoRow('Chức vụ', _safeText(profile.position)),
              _InfoRow('Ngày tham gia', _formatDate(profile.joinDate)),
            ],
          ),
          const SizedBox(height: 12),
          _InfoSection(
            title: 'Hoạt động tài khoản',
            icon: Icons.access_time_rounded,
            rows: [
              _InfoRow(
                'Đăng nhập gần nhất',
                _formatDateTime(profile.lastLoginDate),
              ),
              _InfoRow(
                'Ngày tạo tài khoản',
                _formatDateTime(profile.createdDate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyAvatar() {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
    );
  }

  Widget _buildFaceProfileSummaryIcon({required bool hasFaceProfile}) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: hasFaceProfile
            ? const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        hasFaceProfile
            ? Icons.verified_user_rounded
            : Icons.face_retouching_natural_rounded,
        color: hasFaceProfile ? const Color(0xFF2E7D32) : _kBlue,
        size: 30,
      ),
    );
  }

  Widget _buildFaceMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF607D8B)),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF546E7A),
                height: 1.4,
              ),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: _kTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FaceStatusChip extends StatelessWidget {
  const _FaceStatusChip({required this.hasFaceProfile});

  final bool hasFaceProfile;

  @override
  Widget build(BuildContext context) {
    final color = hasFaceProfile ? const Color(0xFF00695C) : _kBlue;
    final label = hasFaceProfile ? 'Đã đăng ký' : 'Chưa đăng ký';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Column(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF1565C0), size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE3F2FD)),
          ...rows.map((row) => _buildRow(row)),
        ],
      ),
    );
  }

  Widget _buildRow(_InfoRow row) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF546E7A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0D1B2A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}


