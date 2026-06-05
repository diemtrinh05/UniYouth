import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../core/error/attendance_error_mapper.dart';
import '../../../../../core/network/retry_policy/rate_limit_policy.dart';
import '../../../../../domain/entities/registration/registration_status.dart';
import '../../../../../domain/usecases/attendance/check_attendance_status_usecase.dart';
import '../../../../../domain/usecases/events/get_event_detail_usecase.dart';
import '../../../../../domain/usecases/registration/cancel_registration_usecase.dart';
import '../../../../../domain/usecases/registration/get_my_registration_usecase.dart';
import '../../../../../domain/usecases/registration/register_event_usecase.dart';
import '../../../app/providers/app_provider_graph.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/error_widgets/app_error_snackbar.dart';
import '../../../shared/error_widgets/app_error_view.dart';
import '../../../shared/formatters/date_time_formatter.dart';
import '../../../shared/mappers/event_status_ui_mapper.dart';
import '../../attendance/qr_scan/qr_scan_page_args.dart';
import 'state/event_detail_notifier.dart';
import 'state/event_detail_provider.dart';
import 'state/event_detail_state.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueDark = Color(0xFF0D47A1);
const _kBlueMid = Color(0xFF1976D2);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kCyan = Color(0xFF00BCD4);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);
const _kSuccess = Color(0xFF2E7D32);
const _kWarn = Color(0xFFEF6C00);
const _kDanger = Color(0xFFC62828);

class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({
    super.key,
    required this.eventId,
    required this.getEventDetailUseCase,
    required this.getMyRegistrationUseCase,
    required this.registerEventUseCase,
    required this.cancelRegistrationUseCase,
    required this.checkAttendanceStatusUseCase,
  });

  final int eventId;
  final GetEventDetailUseCase getEventDetailUseCase;
  final GetMyRegistrationUseCase getMyRegistrationUseCase;
  final RegisterEventUseCase registerEventUseCase;
  final CancelRegistrationUseCase cancelRegistrationUseCase;
  final CheckAttendanceStatusUseCase checkAttendanceStatusUseCase;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  final TextEditingController _cancellationReasonController =
      TextEditingController();
  late final EventDetailNotifierDependencies _eventDetailDependencies;
  late final StateNotifierProvider<EventDetailNotifier, EventDetailState>
  _eventDetailStateProvider;
  String? _lastFeedbackMessage;

  @override
  void initState() {
    super.initState();
    _eventDetailDependencies = EventDetailNotifierDependencies(
      eventId: widget.eventId,
      getEventDetailUseCase: widget.getEventDetailUseCase,
      getMyRegistrationUseCase: widget.getMyRegistrationUseCase,
      registerEventUseCase: widget.registerEventUseCase,
      cancelRegistrationUseCase: widget.cancelRegistrationUseCase,
      checkAttendanceStatusUseCase: widget.checkAttendanceStatusUseCase,
      notifyEventChanged: ref
          .read(eventRefreshSignalProvider.notifier)
          .notifyEventChanged,
    );
    _eventDetailStateProvider = eventDetailNotifierByDependenciesProvider(
      _eventDetailDependencies,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_refreshData());
    });
  }

  @override
  void dispose() {
    _cancellationReasonController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() =>
      ref.read(_eventDetailStateProvider.notifier).refreshData();

  Future<void> _loadMyRegistrationStatus() =>
      ref.read(_eventDetailStateProvider.notifier).loadMyRegistrationStatus();

  Future<void> _loadAttendanceStatus() =>
      ref.read(_eventDetailStateProvider.notifier).loadAttendanceStatus();

  Future<void> _openCheckInScanner() async {
    final state = ref.read(_eventDetailStateProvider);
    if (state.isOpeningCheckIn) return;
    final attendanceStatus = state.attendanceStatus;
    if (attendanceStatus != null && attendanceStatus.hasCheckedIn) {
      return;
    }

    ref.read(_eventDetailStateProvider.notifier).setOpeningCheckIn(true);
    try {
      final enableFaceVerification =
          state.eventDetail?.enableFaceVerification ?? false;
      final result = await Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.attendanceQrScan,
        arguments: AttendanceQrScanPageArgs(
          popOnSuccess: true,
          enableFaceVerification: enableFaceVerification,
        ),
      );
      if (!mounted) {
        return;
      }
      await ref
          .read(_eventDetailStateProvider.notifier)
          .handleCheckInResult(didCheckIn: result == true);
    } finally {
      ref.read(_eventDetailStateProvider.notifier).setOpeningCheckIn(false);
    }
  }

  Future<void> _registerForEvent() =>
      ref.read(_eventDetailStateProvider.notifier).registerForEvent();

  Future<void> _cancelRegistration() async {
    final reason = _cancellationReasonController.text.trim();
    await ref
        .read(_eventDetailStateProvider.notifier)
        .cancelRegistration(cancellationReason: reason);
  }

  void _showSnackBar(String message) =>
      AppErrorSnackBar.show(context, message: message);

  String _formatDateTime(DateTime? value) {
    return DateTimeFormatter.formatDateTime(value);
  }

  Color _statusColor(int status) {
    return EventStatusUiMapper.foregroundColor(status);
  }

  String _buildLocationGuidance(EventDetail detail) {
    final locationName = (detail.locationName ?? '').trim();
    if (locationName.isNotEmpty && detail.allowRadius != null) {
      return 'Đến đúng địa điểm "$locationName" và đứng trong phạm vi ${detail.allowRadius}m quanh điểm check-in.';
    }
    if (detail.allowRadius != null) {
      return 'Đứng trong phạm vi ${detail.allowRadius}m quanh vị trí check-in do ban tổ chức cấu hình.';
    }
    if (locationName.isNotEmpty) {
      return 'Đến đúng địa điểm "$locationName" trước khi mở máy quét QR.';
    }
    return 'Ban tổ chức sẽ hướng dẫn vị trí check-in cụ thể khi sự kiện diễn ra.';
  }

  String _buildRegistrationRule(EventDetail detail) {
    if (detail.isRegistrationClosed) {
      return 'Đăng ký đã đóng. Bạn chỉ có thể tham gia nếu đã đăng ký trước đó.';
    }
    if (!detail.hasAvailableSlots) {
      return 'Sự kiện đã đủ số lượng đăng ký. Theo dõi thông báo từ ban tổ chức nếu có suất trống.';
    }
    return detail.registrationDeadline != null
        ? 'Bạn cần đăng ký trước ${_formatDateTime(detail.registrationDeadline)} để đủ điều kiện check-in.'
        : 'Bạn cần đăng ký hợp lệ trước khi mở máy quét QR.';
  }

  String _buildFaceRule(EventDetail detail) {
    return detail.enableFaceVerification
        ? 'Sự kiện này yêu cầu chụp khuôn mặt trước khi gửi check-in.'
        : 'Sự kiện này không yêu cầu xác thực khuôn mặt khi check-in.';
  }

  String _buildInvalidAttendanceMessage(AttendanceCheckStatus status) {
    final mapped = AttendanceErrorMapper.mapInvalidCheckInResult(
      isValid: false,
      invalidReason: status.invalidReason,
      distance: null,
    );
    return mapped?.message ??
        'Điểm danh đã được ghi nhận nhưng chưa hợp lệ theo quy tắc hiện tại.';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EventDetailState>(_eventDetailStateProvider, (previous, next) {
      final feedbackMessage = next.feedbackMessage;
      if (feedbackMessage != null && feedbackMessage != _lastFeedbackMessage) {
        _showSnackBar(feedbackMessage);
      }
      _lastFeedbackMessage = feedbackMessage;

      if (previous?.registrationState?.isRegistered == true &&
          next.registrationState?.isRegistered == false) {
        _cancellationReasonController.clear();
      }

      if (feedbackMessage != null) {
        ref.read(_eventDetailStateProvider.notifier).clearFeedbackMessage();
      }
    });
    final state = ref.watch(_eventDetailStateProvider);
    return Scaffold(backgroundColor: _kBg, body: _buildBody(state));
  }

  Widget _buildBody(EventDetailState state) {
    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kBlue)),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: _kTextDark,
        ),
        body: AppErrorView(
          title: 'Không thể tải chi tiết sự kiện',
          message: state.errorMessage!,
          onRetry: _refreshData,
        ),
      );
    }

    final detail = state.eventDetail;
    if (detail == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final statusColor = _statusColor(detail.status);

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: _kBlue,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _kBlueDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _HeroMediaCarousel(images: detail.images),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x330D47A1),
                          Color(0x660D47A1),
                          Color(0xE60D1B2A),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 96, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if ((detail.eventType?.typeName ?? '').trim().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              detail.eventType?.typeName ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Text(
                          detail.eventName.isEmpty ? 'Sự kiện' : detail.eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _HeroBadge(
                              label: detail.statusName ?? 'Không rõ',
                              color: statusColor,
                            ),
                            if (detail.hasAvailableSlots)
                              const _HeroBadge(
                                label: 'Còn chỗ',
                                color: _kCyan,
                              ),
                            if (detail.isRegistrationClosed)
                              const _HeroBadge(
                                label: 'Hết hạn đăng ký',
                                color: Color(0xFFEF5350),
                              ),
                            if (detail.enableFaceVerification)
                              const _HeroBadge(
                                label: 'Có xác thực khuôn mặt',
                                color: _kSuccess,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Điều kiện tham gia & điểm danh'),
                  const SizedBox(height: 8),
                  _InfoCard(
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _RuleChip(
                              icon: Icons.app_registration_rounded,
                              title: 'Đăng ký',
                              description: detail.isRegistrationClosed
                                  ? 'Đã đóng đăng ký'
                                  : 'Mở đăng ký nếu còn chỗ',
                              color: detail.isRegistrationClosed
                                  ? _kDanger
                                  : _kSuccess,
                            ),
                            _RuleChip(
                              icon: Icons.gps_fixed_rounded,
                              title: 'GPS',
                              description: detail.allowRadius != null
                                  ? 'Trong phạm vi ${detail.allowRadius}m'
                                  : 'Theo cấu hình sự kiện',
                              color: _kBlueMid,
                            ),
                            _RuleChip(
                              icon: Icons.face_retouching_natural_rounded,
                              title: 'Khuôn mặt',
                              description: detail.enableFaceVerification
                                  ? 'Bắt buộc trước khi gửi check-in'
                                  : 'Không bắt buộc',
                              color: detail.enableFaceVerification
                                  ? _kSuccess
                                  : _kBlueMid,
                            ),
                            const _RuleChip(
                              icon: Icons.workspace_premium_rounded,
                              title: 'Điểm thưởng',
                              description:
                                  'Cộng tự động sau khi điểm danh hợp lệ',
                              color: Color(0xFFF9A825),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _CalloutCard(
                          icon: Icons.rule_folder_outlined,
                          title: 'Quy tắc tham gia',
                          message: _buildRegistrationRule(detail),
                          color: _kBlueMid,
                        ),
                        const SizedBox(height: 10),
                        _CalloutCard(
                          icon: Icons.place_outlined,
                          title: 'Hướng dẫn vị trí',
                          message: _buildLocationGuidance(detail),
                          color: const Color(0xFF00897B),
                        ),
                        const SizedBox(height: 10),
                        _CalloutCard(
                          icon: Icons.camera_front_outlined,
                          title: 'Quy tắc check-in',
                          message: _buildFaceRule(detail),
                          color: detail.enableFaceVerification
                              ? _kSuccess
                              : _kBlueMid,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'Thông tin sự kiện'),
                  const SizedBox(height: 8),
                  _InfoCard(
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.schedule_rounded,
                          label: 'Bắt đầu',
                          value: _formatDateTime(detail.startTime),
                        ),
                        _InfoTile(
                          icon: Icons.schedule_outlined,
                          label: 'Kết thúc',
                          value: _formatDateTime(detail.endTime),
                        ),
                        _InfoTile(
                          icon: Icons.location_on_rounded,
                          label: 'Địa điểm',
                          value: (detail.locationName ?? '').trim().isEmpty
                              ? 'Không có'
                              : detail.locationName!,
                        ),
                        _InfoTile(
                          icon: Icons.group_rounded,
                          label: 'Số lượng',
                          value:
                              '${detail.currentParticipants ?? 0} / ${detail.maxParticipants ?? '∞'}',
                        ),
                        _InfoTile(
                          icon: Icons.event_busy_rounded,
                          label: 'Hạn đăng ký',
                          value: _formatDateTime(detail.registrationDeadline),
                        ),
                        _InfoTile(
                          icon: Icons.manage_accounts_rounded,
                          label: 'Người tạo',
                          value: (detail.createdByName ?? '').trim().isEmpty
                              ? 'Không có'
                              : detail.createdByName!,
                        ),
                      ],
                    ),
                  ),
                  if ((detail.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionTitle(title: 'Mô tả sự kiện'),
                    const SizedBox(height: 8),
                    _InfoCard(
                      child: Text(
                        detail.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _kTextDark,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'Đăng ký của tôi'),
                  const SizedBox(height: 8),
                  _buildRegistrationSection(state),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'Điểm danh của tôi'),
                  const SizedBox(height: 8),
                  _buildAttendanceSection(state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationSection(EventDetailState state) {
    if (state.isRegistrationLoading) {
      return const _InfoCard(
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
            ),
            SizedBox(width: 10),
            Text(
              'Đang tải trạng thái đăng ký...',
              style: TextStyle(fontSize: 13, color: _kTextMid),
            ),
          ],
        ),
      );
    }

    if (state.registrationErrorMessage != null) {
      return _InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.registrationErrorMessage!,
              style: const TextStyle(fontSize: 13, color: _kDanger),
            ),
            const SizedBox(height: 10),
            _SecondaryButton(label: 'Tải lại', onTap: _loadMyRegistrationStatus),
          ],
        ),
      );
    }

    final registrationState = state.registrationState;
    if (registrationState == null) {
      return const _InfoCard(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: _kTextMid, fontSize: 13),
        ),
      );
    }

    final detail = state.eventDetail;
    final isRegistrationClosed = detail?.isRegistrationClosed ?? false;
    final hasAvailableSlots = detail?.hasAvailableSlots ?? true;
    final canRegister = !isRegistrationClosed && hasAvailableSlots;
    final registerDisabledReason = isRegistrationClosed
        ? 'Đã hết hạn đăng ký.'
        : (!hasAvailableSlots ? 'Sự kiện đã đủ số lượng.' : null);

    if (!registrationState.isRegistered) {
      return _InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CalloutCard(
              icon: Icons.info_outline_rounded,
              title: 'Bạn chưa đăng ký sự kiện này',
              message:
                  'Bạn cần đăng ký hợp lệ trước khi có thể quét QR để điểm danh.',
              color: _kBlueMid,
            ),
            if (registerDisabledReason != null) ...[
              const SizedBox(height: 10),
              Text(
                registerDisabledReason,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kTextMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _PrimaryButton(
              label: state.isRegisterRateLimited
                  ? RateLimitPolicy.retryLabel(
                      seconds: state.registerCooldownSeconds,
                    )
                  : (canRegister ? 'Đăng ký ngay' : 'Không thể đăng ký'),
              icon: Icons.how_to_reg_rounded,
              isLoading: state.isRegistering,
              onTap: (!canRegister || state.isRegistering)
                  ? null
                  : _registerForEvent,
            ),
          ],
        ),
      );
    }

    final registration = registrationState.registration;
    if (registration == null) {
      return const SizedBox.shrink();
    }

    final isCancelled =
        registration.registrationStatus == RegistrationStatus.cancelled;

    if (isCancelled) {
      return _InfoCard(
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.cancel_outlined,
              label: 'Trạng thái',
              value: registration.status ?? 'Đã hủy',
            ),
            if (registerDisabledReason != null) ...[
              const SizedBox(height: 10),
              Text(
                registerDisabledReason,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kTextMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _PrimaryButton(
              label: state.isRegisterRateLimited
                  ? RateLimitPolicy.retryLabel(
                      seconds: state.registerCooldownSeconds,
                    )
                  : (canRegister ? 'Đăng ký lại' : 'Không thể đăng ký'),
              icon: Icons.redo_rounded,
              isLoading: state.isRegistering,
              onTap: (!canRegister || state.isRegistering)
                  ? null
                  : _registerForEvent,
            ),
          ],
        ),
      );
    }

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoTile(
            icon: Icons.badge_rounded,
            label: 'Mã đăng ký',
            value: registration.registrationId.toString(),
          ),
          _InfoTile(
            icon: Icons.person_rounded,
            label: 'Họ tên',
            value: registration.userFullName ?? 'Không có',
          ),
          _InfoTile(
            icon: Icons.schedule_rounded,
            label: 'Thời gian đăng ký',
            value: _formatDateTime(registration.registerTime),
          ),
          _InfoTile(
            icon: Icons.check_circle_rounded,
            label: 'Trạng thái',
            value: registration.status ?? 'Không rõ',
          ),
          const SizedBox(height: 10),
          const _CalloutCard(
            icon: Icons.verified_user_outlined,
            title: 'Bạn đã đủ điều kiện mở máy quét QR',
            message:
                'Khi sự kiện bắt đầu, quay lại mục điểm danh bên dưới để quét QR.',
            color: _kSuccess,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cancellationReasonController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Lý do hủy (không bắt buộc)',
              hintStyle: const TextStyle(color: _kTextMid, fontSize: 13),
              filled: true,
              fillColor: _kBlueLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _SecondaryButton(
            label: 'Hủy đăng ký',
            isLoading: state.isCancelling,
            onTap: state.isCancelling ? null : _cancelRegistration,
            color: _kDanger,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(EventDetailState state) {
    if (state.isAttendanceStatusLoading) {
      return const _InfoCard(
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
            ),
            SizedBox(width: 10),
            Text(
              'Đang tải trạng thái điểm danh...',
              style: TextStyle(fontSize: 13, color: _kTextMid),
            ),
          ],
        ),
      );
    }

    if (state.attendanceStatusErrorMessage != null) {
      return _InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.attendanceStatusErrorMessage!,
              style: const TextStyle(fontSize: 13, color: _kDanger),
            ),
            const SizedBox(height: 10),
            _SecondaryButton(label: 'Tải lại', onTap: _loadAttendanceStatus),
          ],
        ),
      );
    }

    final status = state.attendanceStatus;
    if (status == null) {
      return const _InfoCard(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: _kTextMid, fontSize: 13),
        ),
      );
    }

    final detail = state.eventDetail;
    final isRegistered = state.registrationState?.isRegistered == true;

    if (status.hasCheckedIn && status.isValid == false) {
      final invalidAttendanceMessage = _buildInvalidAttendanceMessage(status);
      return _InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CalloutCard(
              icon: Icons.warning_amber_rounded,
              title: 'Điểm danh chưa hợp lệ',
              message:
                  'Lượt check-in đã được ghi nhận nhưng chưa đạt điều kiện xác nhận.',
              color: _kWarn,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                invalidAttendanceMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8D4B00),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _CalloutCard(
              icon: Icons.refresh_rounded,
              title: 'Bước tiếp theo',
              message:
                  'Nếu ban tổ chức còn mở điểm danh, hãy quay lại máy quét QR để thử lại với GPS ổn định hơn hoặc chụp khuôn mặt rõ hơn.',
              color: _kWarn,
            ),
          ],
        ),
      );
    }

    if (status.hasCheckedIn) {
      return const _InfoCard(
        child: _CalloutCard(
          icon: Icons.verified_rounded,
          title: 'Bạn đã điểm danh thành công',
          message:
              'Hệ thống đã ghi nhận check-in của bạn. Điểm thưởng sẽ được cộng tự động nếu sự kiện có cấu hình điểm.',
          color: _kSuccess,
        ),
      );
    }

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CalloutCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Bạn chưa điểm danh',
            message: isRegistered
                ? 'Khi sự kiện đang diễn ra, bạn có thể mở máy quét QR bên dưới để bắt đầu điểm danh.'
                : 'Bạn cần đăng ký tham gia trước khi có thể quét QR điểm danh.',
            color: _kBlueMid,
          ),
          const SizedBox(height: 10),
          const _CalloutCard(
            icon: Icons.schedule_outlined,
            title: 'Điều kiện mở check-in',
            message:
                'Check-in chỉ hợp lệ khi sự kiện đang diễn ra, bạn đứng đúng khu vực và hoàn tất các bước xác thực mà sự kiện yêu cầu.',
            color: _kBlueMid,
          ),
          const SizedBox(height: 10),
          _CalloutCard(
            icon: Icons.place_outlined,
            title: 'Lưu ý vị trí',
            message: detail != null
                ? _buildLocationGuidance(detail)
                : 'Kiểm tra vị trí theo hướng dẫn của ban tổ chức trước khi quét QR.',
            color: const Color(0xFF00897B),
          ),
          if (detail?.enableFaceVerification == true) ...[
            const SizedBox(height: 10),
            const _CalloutCard(
              icon: Icons.face_retouching_natural_rounded,
              title: 'Sự kiện có xác thực khuôn mặt',
              message:
                  'Sau khi quét QR và lấy GPS, ứng dụng sẽ yêu cầu chụp khuôn mặt trước khi gửi check-in.',
              color: _kSuccess,
            ),
          ],
          const SizedBox(height: 12),
          _PrimaryButton(
            label: 'Mở máy quét QR',
            icon: Icons.qr_code_scanner_rounded,
            isLoading: state.isOpeningCheckIn,
            onTap: state.isOpeningCheckIn || !isRegistered
                ? null
                : _openCheckInScanner,
            gradientColors: const [Color(0xFF00BCD4), Color(0xFF0097A7)],
          ),
          if (!isRegistered) ...[
            const SizedBox(height: 8),
            const Text(
              'Nút quét QR chỉ bật sau khi bạn đăng ký hợp lệ.',
              style: TextStyle(
                fontSize: 12,
                color: _kTextMid,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMediaCarousel extends StatelessWidget {
  const _HeroMediaCarousel({required this.images});

  final List<EventDetailImage> images;

  @override
  Widget build(BuildContext context) {
    final imageUrls = images
        .map((image) => (image.imageUrl ?? '').trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);

    if (imageUrls.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_kBlueDark, _kBlueMid, Color(0xFF0288D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    return _HeroImageCarousel(imageUrls: imageUrls);
  }
}

class _HeroImageCarousel extends StatefulWidget {
  const _HeroImageCarousel({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_HeroImageCarousel> createState() => _HeroImageCarouselState();
}

class _HeroImageCarouselState extends State<_HeroImageCarousel> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _restartAutoSlide();
  }

  @override
  void didUpdateWidget(covariant _HeroImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _currentPage = 0;
      _pageController.jumpToPage(0);
      _restartAutoSlide();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _restartAutoSlide() {
    _autoSlideTimer?.cancel();
    if (widget.imageUrls.length <= 1) {
      return;
    }

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      final nextPage = (_currentPage + 1) % widget.imageUrls.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) {
            if (!mounted) {
              return;
            }
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              widget.imageUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: _kBlueLight,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  color: _kBlueSky,
                  size: 44,
                ),
              ),
            );
          },
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            right: 16,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.imageUrls.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: EdgeInsets.only(
                        right: index == widget.imageUrls.length - 1 ? 0 : 6,
                      ),
                      width: isActive ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
      ],
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
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: _kTextDark,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: _kBlue),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
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
              style: const TextStyle(
                fontSize: 13,
                color: _kTextDark,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: _kTextDark,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextDark,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.isLoading = false,
    this.onTap,
    this.gradientColors = const [_kBlue, _kBlueSky],
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.65 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: onTap == null
                ? null
                : [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    this.isLoading = false,
    this.onTap,
    this.color = _kBlue,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.65 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
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
              : Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
