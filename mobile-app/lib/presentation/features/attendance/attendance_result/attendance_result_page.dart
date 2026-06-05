import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/attendance_error_mapper.dart';
import '../../../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../app/router/app_routes.dart';
import '../../../navigation/state/navigation_shell_provider.dart';
import '../../../shared/formatters/date_time_formatter.dart';
import '../../../shared/formatters/distance_formatter.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);
const _kSuccess = Color(0xFF2E7D32);
const _kSuccessBg = Color(0xFFE8F5E9);
const _kWarn = Color(0xFFE65100);
const _kWarnBg = Color(0xFFFFF3E0);

class AttendanceResultPage extends StatelessWidget {
  const AttendanceResultPage({super.key, required this.result});

  final CheckInResult result;

  void _closeToHome(BuildContext context) {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(navigationShellNotifierProvider.notifier).selectTab(
      NavigationShellTab.home,
    );

    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil(
      (route) => route.settings.name == AppRoutes.app || route.isFirst,
    );
  }

  String _formatDistance(double? value) => DistanceFormatter.formatMeters(value);

  String _formatFaceConfidence(double? value) {
    if (value == null) return 'Không có';
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  bool get _hasFaceSummary {
    return (result.faceVerificationStatus ?? '').trim().isNotEmpty ||
        result.faceVerified != null ||
        result.faceConfidence != null ||
        result.riskScore != null ||
        (result.riskLevel ?? '').trim().isNotEmpty;
  }

  // ignore: unused_element
  String _resolveFaceStatusLabel() {
    final status = (result.faceVerificationStatus ?? '').trim();
    if (status.isEmpty) {
      return 'Không có';
    }

    switch (status) {
      case 'Matched':
        return 'Khớp';
      case 'Review':
        return 'Cần kiểm tra';
      case 'Mismatch':
        return 'Không khớp';
      case 'TechnicalError':
        return 'Lỗi kỹ thuật';
      case 'ProfileMissing':
        return 'Thiếu hồ sơ';
      case 'PayloadMissing':
        return 'Thiếu ảnh';
      case 'NoFaceDetected':
        return 'Không thấy mặt';
      case 'MultipleFacesDetected':
        return 'Nhiều khuôn mặt';
      case 'BlurryImage':
        return 'Ảnh mờ';
      case 'InvalidPayload':
        return 'Ảnh không hợp lệ';
      case 'NotRequested':
        return 'Không yêu cầu';
      default:
        return status;
    }
  }

  Color _faceStatusColor() {
    switch ((result.faceVerificationStatus ?? '').trim()) {
      case 'Matched':
        return _kSuccess;
      case 'Review':
        return const Color(0xFFF9A825);
      case 'Mismatch':
      case 'TechnicalError':
      case 'NoFaceDetected':
      case 'MultipleFacesDetected':
      case 'BlurryImage':
      case 'InvalidPayload':
        return _kWarn;
      case 'ProfileMissing':
      case 'PayloadMissing':
      case 'NotRequested':
      default:
        return _kTextMid;
    }
  }

  // ignore: unused_element
  String? _resolveFaceStatusMessage() {
    final backendMessage = result.faceVerificationMessage?.trim();
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    switch ((result.faceVerificationStatus ?? '').trim()) {
      case 'Matched':
        return 'Khuôn mặt đã được xác thực thành công.';
      case 'Review':
        return 'Ảnh khuôn mặt đã được ghi nhận nhưng cần kiểm tra thêm.';
      case 'Mismatch':
        return 'Ảnh khuôn mặt chưa khớp với hồ sơ đã đăng ký.';
      case 'TechnicalError':
        return 'Hệ thống chưa xác thực được khuôn mặt ở lần điểm danh này.';
      case 'ProfileMissing':
        return 'Tài khoản chưa có hồ sơ khuôn mặt để đối chiếu.';
      case 'PayloadMissing':
        return 'Hệ thống chưa nhận được ảnh khuôn mặt từ ứng dụng.';
      case 'NoFaceDetected':
        return 'Ảnh gửi lên không nhận diện được khuôn mặt.';
      case 'MultipleFacesDetected':
        return 'Ảnh gửi lên có nhiều khuôn mặt, vui lòng chụp lại.';
      case 'BlurryImage':
        return 'Ảnh khuôn mặt bị mờ, vui lòng chụp lại rõ hơn.';
      case 'InvalidPayload':
        return 'Dữ liệu ảnh khuôn mặt không hợp lệ.';
      case 'NotRequested':
        return 'Sự kiện này không yêu cầu xác thực khuôn mặt.';
      default:
        return null;
    }
  }

  String _resolveSafeFaceStatusLabel() {
    switch ((result.faceVerificationStatus ?? '').trim()) {
      case 'Matched':
        return 'Đã khớp';
      case 'Review':
        return 'Cần rà soát';
      case 'Mismatch':
        return 'Không khớp';
      case 'TechnicalError':
        return 'Lỗi kỹ thuật';
      case 'ProfileMissing':
        return 'Thiếu hồ sơ';
      case 'PayloadMissing':
        return 'Thiếu ảnh';
      case 'NoFaceDetected':
        return 'Không thấy mặt';
      case 'MultipleFacesDetected':
        return 'Nhiều khuôn mặt';
      case 'BlurryImage':
        return 'Ảnh mờ';
      case 'InvalidPayload':
        return 'Ảnh không hợp lệ';
      case 'NotRequested':
        return 'Không yêu cầu';
      case '':
        return 'Không có';
      default:
        return (result.faceVerificationStatus ?? '').trim();
    }
  }

  String _resolveRiskLevelDisplay() {
    switch ((result.riskLevel ?? '').trim()) {
      case 'Low':
        return 'Thấp';
      case 'Medium':
        return 'Trung bình';
      case 'High':
        return 'Cao';
      case 'Critical':
        return 'Nghiêm trọng';
      case '':
        return 'Không có';
      default:
        return (result.riskLevel ?? '').trim();
    }
  }

  String? _resolveSafeFaceStatusMessage() {
    final backendMessage = _sanitizeFaceMessage(result.faceVerificationMessage);
    if (backendMessage != null) {
      return backendMessage;
    }

    switch ((result.faceVerificationStatus ?? '').trim()) {
      case 'Matched':
        return 'Khuôn mặt đã được hệ thống xác minh thành công.';
      case 'Review':
        return 'Ảnh khuôn mặt đã được ghi nhận và có thể cần kiểm tra thêm từ hệ thống.';
      case 'Mismatch':
        return 'Hệ thống chưa thể đối chiếu ảnh khuôn mặt trùng khớp ở lần điểm danh này.';
      case 'TechnicalError':
        return 'Hệ thống chưa thể xử lý xác minh khuôn mặt ở lần điểm danh này.';
      case 'ProfileMissing':
        return 'Tài khoản của bạn hiện chưa có hồ sơ khuôn mặt để đối chiếu.';
      case 'PayloadMissing':
        return 'Hệ thống chưa nhận được ảnh khuôn mặt từ ứng dụng.';
      case 'NoFaceDetected':
        return 'Ảnh gửi lên chưa nhận diện được khuôn mặt.';
      case 'MultipleFacesDetected':
        return 'Ảnh gửi lên có nhiều khuôn mặt, vui lòng chụp lại rõ một người.';
      case 'BlurryImage':
        return 'Ảnh khuôn mặt bị mờ, vui lòng chụp lại rõ hơn.';
      case 'InvalidPayload':
        return 'Dữ liệu ảnh khuôn mặt không hợp lệ.';
      case 'NotRequested':
        return 'Sự kiện này không yêu cầu xác minh khuôn mặt.';
      default:
        return null;
    }
  }

  String? _sanitizeFaceMessage(String? rawMessage) {
    final message = rawMessage?.trim();
    if (message == null || message.isEmpty) {
      return null;
    }

    final lowered = message.toLowerCase();
    const blockedKeywords = [
      'gian lận',
      'fraud',
      'rủi ro',
      'risk',
      'nội bộ',
      'internal',
      'rule engine',
      'scoring',
      'blacklist',
    ];

    if (blockedKeywords.any(lowered.contains)) {
      return null;
    }

    return message;
  }

  String? _resolveFaceGuidance() {
    switch ((result.faceVerificationStatus ?? '').trim()) {
      case 'Review':
      case 'Mismatch':
      case 'TechnicalError':
      case 'NoFaceDetected':
      case 'MultipleFacesDetected':
      case 'BlurryImage':
      case 'InvalidPayload':
      case 'ProfileMissing':
      case 'PayloadMissing':
        return 'Lượt điểm danh này chưa đạt vì xác minh khuôn mặt không thành công. Nếu hệ thống còn cho phép thử lại, hãy quay lại màn quét QR và chụp lại khuôn mặt rõ hơn.';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = result.isValid;
    final pointsAwarded = result.pointsAwarded;
    final faceStatusMessage = _resolveSafeFaceStatusMessage();
    final faceGuidance = _resolveFaceGuidance();
    final invalidMapping = AttendanceErrorMapper.mapInvalidCheckInResult(
      isValid: result.isValid,
      invalidReason: result.invalidReason,
      distance: result.distance,
      faceVerificationStatus: result.faceVerificationStatus,
    );

    final heroColor = isValid ? _kSuccess : _kWarn;
    final heroBg = isValid ? _kSuccessBg : _kWarnBg;
    final heroIcon = isValid
        ? Icons.check_circle_rounded
        : Icons.warning_amber_rounded;
    final heroTitle = isValid ? 'Điểm danh hợp lệ!' : 'Điểm danh chưa hợp lệ';
    final heroSubtitle = isValid
        ? 'Bạn đã điểm danh thành công. Điểm thưởng sẽ được cộng theo kết quả từ hệ thống.'
        : (invalidMapping?.message ??
              'Vui lòng kiểm tra lại điều kiện điểm danh.');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeToHome(context);
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _kTextDark,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => _closeToHome(context),
              ),
              title: const Text(
                'Kết quả điểm danh',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: _kTextDark,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(
                      heroColor: heroColor,
                      heroBg: heroBg,
                      heroIcon: heroIcon,
                      heroTitle: heroTitle,
                      heroSubtitle: heroSubtitle,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(title: 'Thông tin sự kiện'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        _InfoTile(
                          icon: Icons.event_rounded,
                          label: 'Sự kiện',
                          value: (result.eventName ?? '').trim().isEmpty
                              ? 'Không có'
                              : result.eventName!,
                        ),
                        const _Divider(),
                        _InfoTile(
                          icon: Icons.schedule_rounded,
                          label: 'Thời gian',
                          value: DateTimeFormatter.formatDateTime(
                            result.checkInTime,
                            withSeconds: true,
                          ),
                        ),
                        const _Divider(),
                        _InfoTile(
                          icon: Icons.place_rounded,
                          label: 'Khoảng cách',
                          value: _formatDistance(result.distance),
                          valueColor: _distanceColor(result.distance),
                        ),
                        const _Divider(),
                        _InfoTile(
                          icon: Icons.badge_rounded,
                          label: 'Mã điểm danh',
                          value: result.attendanceId?.toString() ?? 'Không có',
                        ),
                      ],
                    ),
                    if (_hasFaceSummary) ...[
                      const SizedBox(height: 20),
                      const _SectionTitle(title: 'Xác thực khuôn mặt'),
                      const SizedBox(height: 10),
                      _InfoCard(
                        children: [
                          _InfoTile(
                            icon: Icons.verified_user_rounded,
                            label: 'Trạng thái',
                            value: _resolveSafeFaceStatusLabel(),
                            valueColor: _faceStatusColor(),
                          ),
                          const _Divider(),
                          _InfoTile(
                            icon: Icons.face_retouching_natural_rounded,
                            label: 'Xác minh',
                            value: result.faceVerified == null
                                ? 'Không có'
                                : (result.faceVerified! ? 'Có' : 'Không'),
                            valueColor: result.faceVerified == null
                                ? _kTextMid
                                : (result.faceVerified! ? _kSuccess : _kWarn),
                          ),
                          const _Divider(),
                          _InfoTile(
                            icon: Icons.analytics_rounded,
                            label: 'Độ tin cậy',
                            value: _formatFaceConfidence(result.faceConfidence),
                          ),
                          if (result.riskScore != null ||
                              (result.riskLevel ?? '').trim().isNotEmpty) ...[
                            const _Divider(),
                            _InfoTile(
                              icon: Icons.shield_outlined,
                              label: 'Mức rủi ro',
                              value:
                                  '${_resolveRiskLevelDisplay()} ${result.riskScore != null ? '(${result.riskScore})' : ''}'
                                      .trim(),
                            ),
                          ],
                        ],
                      ),
                      if (faceStatusMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _faceStatusColor().withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _faceStatusColor().withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: _faceStatusColor(),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  faceStatusMessage,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kTextDark,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (faceGuidance != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kBlueLight),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: _kBlueSky,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  faceGuidance,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kTextDark,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    if (isValid && pointsAwarded != null) ...[
                      const SizedBox(height: 20),
                      const _SectionTitle(title: 'Điểm thưởng nhận được'),
                      const SizedBox(height: 10),
                      _PointsCard(pointsAwarded: pointsAwarded),
                    ],
                    if (!isValid) ...[
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: invalidMapping?.title ?? 'Lý do không hợp lệ',
                      ),
                      const SizedBox(height: 10),
                      _InvalidCard(
                        mapping: invalidMapping,
                        invalidReason: (result.invalidReason ?? '').trim(),
                      ),
                    ],
                    if ((result.message ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const _SectionTitle(title: 'Thông điệp từ hệ thống'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _kBlue.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: _kBlueSky,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                result.message!.trim(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _kTextDark,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => _closeToHome(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isValid
                                ? [_kSuccess, const Color(0xFF388E3C)]
                                : [_kWarn, const Color(0xFFBF360C)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: heroColor.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Đóng',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _distanceColor(double? distance) {
    if (distance == null) return _kTextMid;
    if (distance <= 50) return _kSuccess;
    if (distance <= 150) return const Color(0xFFF9A825);
    return _kWarn;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.heroColor,
    required this.heroBg,
    required this.heroIcon,
    required this.heroTitle,
    required this.heroSubtitle,
  });

  final Color heroColor;
  final Color heroBg;
  final IconData heroIcon;
  final String heroTitle;
  final String heroSubtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: heroBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: heroColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: heroColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: heroColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(heroIcon, color: heroColor, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            heroTitle,
            style: TextStyle(
              color: heroColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            heroSubtitle,
            style: TextStyle(
              color: heroColor.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.pointsAwarded});

  final CheckInPointsAwarded pointsAwarded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${pointsAwarded.points?.toString() ?? '0'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  'điểm',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PointInfoChip(
                  icon: Icons.stars_rounded,
                  label: 'Loại điểm',
                  value: pointsAwarded.pointType ?? 'Không có',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PointInfoChip(
                  icon: Icons.person_rounded,
                  label: 'Vai trò',
                  value: pointsAwarded.roleType ?? 'Không có',
                ),
              ),
            ],
          ),
          if (pointsAwarded.currentTotalPoints != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng điểm hiện tại: ${pointsAwarded.currentTotalPoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PointInfoChip extends StatelessWidget {
  const _PointInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InvalidCard extends StatelessWidget {
  const _InvalidCard({required this.mapping, required this.invalidReason});

  final AttendanceEdgeCaseUi? mapping;
  final String invalidReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kWarnBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kWarn.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: _kWarn, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mapping?.message ??
                      (invalidReason.isEmpty
                          ? 'Không có lý do cụ thể.'
                          : invalidReason),
                  style: const TextStyle(
                    color: _kWarn,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (invalidReason.isNotEmpty &&
              mapping?.type == AttendanceEdgeCaseType.distanceTooFar) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kWarn.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                invalidReason,
                style: const TextStyle(
                  fontSize: 11,
                  color: _kWarn,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: _kTextDark,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kBlue),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _kTextMid,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? _kTextDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


