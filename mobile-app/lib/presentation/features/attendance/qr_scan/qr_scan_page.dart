import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../core/location/location_service.dart';
import '../../../../../core/network/retry_policy/rate_limit_policy.dart';
import '../../../../../core/permissions/camera_permission_service.dart';
import '../../../../../core/permissions/location_permission_service.dart';
import '../../../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../app/providers/app_provider_graph.dart';
import '../attendance_result/attendance_result_page.dart';
import '../face_capture/attendance_face_capture_service.dart';
import '../../../shared/error_widgets/app_error_snackbar.dart';
import 'state/qr_check_in_notifier.dart';
import 'state/qr_check_in_provider.dart';
import 'state/qr_check_in_state.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFF0F7FF);
const _kBlue = Color(0xFF1565C0);
const _kBlueMid = Color(0xFF1976D2);
const _kBlueSky = Color(0xFF42A5F5);
const _kCyan = Color(0xFF00BCD4);
const _kBlueLight = Color(0xFFE3F2FD);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);
const _kError = Color(0xFFC62828);
const _kErrorBg = Color(0xFFFFEBEE);
const _kSuccess = Color(0xFF2E7D32);
const _kWarn = Color(0xFFE65100);

class QrScanPage extends ConsumerStatefulWidget {
  const QrScanPage({
    super.key,
    required this.cameraPermissionService,
    required this.locationPermissionService,
    required this.locationService,
    required this.checkInUseCase,
    required this.faceCaptureService,
    this.popOnSuccess = false,
    this.enableFaceVerification = false,
  });

  final CameraPermissionService cameraPermissionService;
  final LocationPermissionService locationPermissionService;
  final LocationService locationService;
  final CheckInUseCase checkInUseCase;
  final AttendanceFaceCaptureService faceCaptureService;
  final bool popOnSuccess;
  final bool enableFaceVerification;

  @override
  ConsumerState<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends ConsumerState<QrScanPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  late final QrCheckInNotifierDependencies _qrCheckInDependencies;
  late final StateNotifierProvider<QrCheckInNotifier, QrCheckInState>
  _qrCheckInStateProvider;
  String? _lastFeedbackMessage;
  bool _isCapturingFace = false;

  QrCheckInState get _state => ref.read(_qrCheckInStateProvider);
  CameraPermissionState? get _cameraPermissionState =>
      _state.cameraPermissionState;
  bool get _isCheckingCameraPermission => _state.isCheckingCameraPermission;
  bool get _isResolvingLocation => _state.isResolvingLocation;
  int get _checkInCooldownSeconds => _state.checkInCooldownSeconds;
  QrCheckInPhase get _phase => _state.phase;
  String? get _scannedQrToken => _state.scannedQrToken;
  GeoLocationPoint? get _capturedLocation => _state.capturedLocation;
  String? get _faceCaptureErrorMessage => _state.faceCaptureErrorMessage;
  String? get _locationErrorMessage => _state.locationErrorMessage;
  String? get _checkInErrorTitle => _state.checkInErrorTitle;
  String? get _checkInErrorMessage => _state.checkInErrorMessage;
  bool get _isCheckInRateLimited => _state.isCheckInRateLimited;
  _LocationIssueType? get _locationIssueType {
    switch (_state.locationIssueType) {
      case QrLocationIssueType.permissionDenied:
        return _LocationIssueType.permissionDenied;
      case QrLocationIssueType.permissionBlocked:
        return _LocationIssueType.permissionBlocked;
      case QrLocationIssueType.serviceDisabled:
        return _LocationIssueType.serviceDisabled;
      case QrLocationIssueType.unknown:
        return _LocationIssueType.unknown;
      case null:
        return null;
    }
  }

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(_pulseCtrl)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseCtrl.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseCtrl.forward();
        }
      });
    _pulseCtrl.forward();
    _qrCheckInDependencies = QrCheckInNotifierDependencies(
      cameraPermissionService: widget.cameraPermissionService,
      locationPermissionService: widget.locationPermissionService,
      locationService: widget.locationService,
      deviceInfoService: ref.read(checkInDeviceInfoServiceProvider),
      clientDeviceIdService: ref.read(checkInClientDeviceIdServiceProvider),
      checkInUseCase: widget.checkInUseCase,
      getCheckInRequirementsUseCase: ref.read(
        getCheckInRequirementsUseCaseProvider,
      ),
      enableFaceVerification: widget.enableFaceVerification,
    );
    _qrCheckInStateProvider = qrCheckInNotifierByDependenciesProvider(
      _qrCheckInDependencies,
    );
    unawaited(
      ref.read(_qrCheckInStateProvider.notifier).initCameraPermission(),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ── Permissions ────────────────────────────────────────────────────────────
  Future<void> _requestCameraPermission() =>
      ref.read(_qrCheckInStateProvider.notifier).requestCameraPermission();

  // ── Scan ───────────────────────────────────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    final token = _extractQrToken(capture);
    if (token == null) return;
    final handled = await ref
        .read(_qrCheckInStateProvider.notifier)
        .handleQrTokenDetected(token);
    if (!handled || !mounted) {
      return;
    }
    await _scannerController.stop();
  }

  String? _extractQrToken(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Future<void> _scanAgain() async {
    if (_cameraPermissionState != CameraPermissionState.granted) return;
    ref.read(_qrCheckInStateProvider.notifier).resetScanSession();
    await _scannerController.start();
  }

  Future<void> _retryLocationCapture() =>
      ref.read(_qrCheckInStateProvider.notifier).retryLocationCapture();

  Future<void> _retryCheckIn() =>
      ref.read(_qrCheckInStateProvider.notifier).retryCheckIn();

  Future<void> _captureFaceForCheckIn() async {
    if (_isCapturingFace || !mounted) {
      return;
    }

    _isCapturingFace = true;
    try {
      final capturedFace = await widget.faceCaptureService.captureFaceEvidence(
        context,
      );
      if (!mounted) {
        return;
      }
      if (capturedFace == null) {
        ref.read(_qrCheckInStateProvider.notifier).cancelFaceCapture();
        return;
      }

      await ref
          .read(_qrCheckInStateProvider.notifier)
          .completeFaceCapture(capturedFace);
    } finally {
      _isCapturingFace = false;
    }
  }

  Future<void> _openAttendanceResultPage(CheckInResult result) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceResultPage(result: result),
      ),
    );
    if (!mounted) return;
    if (widget.popOnSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    await _scanAgain();
  }

  void _showSnackBar(String message) =>
      AppErrorSnackBar.show(context, message: message);

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    ref.listen<QrCheckInState>(_qrCheckInStateProvider, (previous, next) {
      final feedbackMessage = next.feedbackMessage;
      if (feedbackMessage != null && feedbackMessage != _lastFeedbackMessage) {
        _showSnackBar(feedbackMessage);
      }
      _lastFeedbackMessage = feedbackMessage;

      if (feedbackMessage != null) {
        ref.read(_qrCheckInStateProvider.notifier).clearFeedbackMessage();
      }

      final previousResult = previous?.checkInResult;
      final nextResult = next.checkInResult;
      if (previousResult == null && nextResult != null) {
        unawaited(_openAttendanceResultPage(nextResult));
      }

      final shouldOpenFaceCapture =
          previous?.isAwaitingFaceCapture != true && next.isAwaitingFaceCapture;
      if (shouldOpenFaceCapture) {
        unawaited(_captureFaceForCheckIn());
      }
    });
    ref.watch(_qrCheckInStateProvider);

    late final Widget content;
    if (_isCheckingCameraPermission) {
      content = const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2.5),
        ),
      );
    } else if (_cameraPermissionState != CameraPermissionState.granted) {
      content = _buildPermissionDeniedScreen();
    } else {
      content = Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera
            MobileScanner(controller: _scannerController, onDetect: _onDetect),
            // Vignette with cutout
            if (_scannedQrToken == null)
              Positioned.fill(child: CustomPaint(painter: _VignettePainter())),
            // Scan frame
            if (_scannedQrToken == null) _buildScanOverlay(),
            _buildFlowCardOverlay(),
            // Top bar
            _buildTopBar(),
          ],
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: content,
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Quét QR Điểm danh',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Scan Overlay ───────────────────────────────────────────────────────────
  Widget _buildScanOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Đưa mã QR vào khung bên dưới',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, _) {
              return Container(
                width: 248,
                height: 248,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _kCyan.withValues(alpha: _pulseAnim.value),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    for (final a in [
                      Alignment.topLeft,
                      Alignment.topRight,
                      Alignment.bottomLeft,
                      Alignment.bottomRight,
                    ])
                      Align(
                        alignment: a,
                        child: _ScanCorner(alignment: a),
                      ),
                    Center(
                      child: Opacity(
                        opacity: _pulseAnim.value * 0.35,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _kCyan, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Bottom Panel ───────────────────────────────────────────────────────────
  Widget _buildFlowCardOverlay() {
    final isScanReady = _scannedQrToken == null;
    return SafeArea(
      child: Stack(
        children: [
          if (!isScanReady)
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(color: Colors.black.withValues(alpha: 0.16)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 84, 24, 24),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: isScanReady
                  ? const Alignment(0, 0.64)
                  : Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.98,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey<String>(
                      isScanReady ? 'scan-ready-card' : 'scan-result-card',
                    ),
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 440),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: isScanReady
                          ? _buildHintPanel()
                          : _buildResultPanel(),
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

  _QrPhasePresentation _phasePresentation() {
    switch (_phase) {
      case QrCheckInPhase.preparing:
        return const _QrPhasePresentation(
          title: 'Đang chuẩn bị',
          message:
              'Ứng dụng đang kiểm tra quyền camera và khởi tạo phiên quét.',
          icon: Icons.tune_rounded,
          color: _kBlueMid,
        );
      case QrCheckInPhase.scanning:
        return _QrPhasePresentation(
          title: 'Bước 1: Quét mã QR',
          message: widget.enableFaceVerification
              ? 'Quét mã QR để bắt đầu. Sau đó ứng dụng sẽ lấy GPS và mở camera trước để chụp khuôn mặt.'
              : 'Hướng camera vào mã QR điểm danh. Sau khi quét xong, ứng dụng sẽ tự lấy GPS và gửi điểm danh.',
          icon: Icons.qr_code_scanner_rounded,
          color: _kBlueMid,
        );
      case QrCheckInPhase.resolving:
        return _QrPhasePresentation(
          title: _isResolvingLocation
              ? 'Bước 2: Đang lấy vị trí'
              : 'Đang kiểm tra thông tin điểm danh',
          message: _isResolvingLocation
              ? 'Giữ điện thoại đứng yên trong vài giây để GPS ổn định trước khi gửi điểm danh.'
              : 'Mã QR đã được ghi nhận. Ứng dụng đang kiểm tra điều kiện điểm danh.',
          icon: _isResolvingLocation
              ? Icons.location_searching_rounded
              : Icons.sync_rounded,
          color: _kBlueMid,
        );
      case QrCheckInPhase.faceRequired:
        return _QrPhasePresentation(
          title: 'Bước 3: Cần chụp khuôn mặt',
          message:
              _faceCaptureErrorMessage ??
              'Giữ khuôn mặt ở giữa khung, chỉ một người trong ảnh và tránh ngược sáng trước khi chụp lại.',
          icon: Icons.face_retouching_natural_rounded,
          color: _kWarn,
        );
      case QrCheckInPhase.submitting:
        return const _QrPhasePresentation(
          title: 'Đang gửi điểm danh',
          message:
              'Ứng dụng đã có đủ dữ liệu và đang gửi yêu cầu điểm danh lên hệ thống.',
          icon: Icons.send_rounded,
          color: _kBlueMid,
        );
      case QrCheckInPhase.succeeded:
        return const _QrPhasePresentation(
          title: 'Điểm danh thành công',
          message: 'Kết quả đang được mở. Bạn không cần thao tác thêm.',
          icon: Icons.check_circle_rounded,
          color: _kSuccess,
        );
      case QrCheckInPhase.recoverableError:
        return _QrPhasePresentation(
          title: _checkInErrorTitle ??
              (_faceCaptureErrorMessage != null
                  ? 'Cần chụp lại khuôn mặt'
                  : 'Có thể thử lại'),
          message:
              _locationErrorMessage ??
              _faceCaptureErrorMessage ??
              _checkInErrorMessage ??
              'Bạn có thể xử lý tại màn hình này và thử lại ngay.',
          icon: Icons.refresh_rounded,
          color: _kWarn,
        );
      case QrCheckInPhase.hardError:
        return _QrPhasePresentation(
          title: _checkInErrorTitle ?? 'Không thể tiếp tục điểm danh',
          message:
              _checkInErrorMessage ??
              'Mã QR hoặc trạng thái sự kiện hiện không cho phép điểm danh.',
          icon: Icons.block_rounded,
          color: _kError,
        );
    }
  }

  String? _phaseGuidance() {
    if (_phase == QrCheckInPhase.faceRequired ||
        _faceCaptureErrorMessage != null) {
      return 'Đưa mặt vào giữa khung, bỏ vật che mặt nếu có và giữ máy ổn định trước khi chụp lại.';
    }

    switch (_locationIssueType) {
      case _LocationIssueType.permissionDenied:
        return 'Ứng dụng cần quyền vị trí để xác nhận bạn đang ở trong phạm vi điểm danh.';
      case _LocationIssueType.permissionBlocked:
        return 'Mở cài đặt quyền vị trí để cho phép ứng dụng truy cập GPS.';
      case _LocationIssueType.serviceDisabled:
        return 'Bật GPS của thiết bị rồi quay lại màn hình này để thử lại.';
      case _LocationIssueType.unknown:
        return 'Kiểm tra kết nối GPS hoặc mạng rồi thử lại.';
      case null:
        break;
    }

    if (_isCheckInRateLimited) {
      return 'Bạn cần chờ hết thời gian đếm ngược rồi mới gửi lại điểm danh.';
    }

    if (_phase == QrCheckInPhase.hardError) {
      return 'Hãy quét mã QR khác hoặc liên hệ ban tổ chức nếu bạn cho rằng đây là lỗi hệ thống.';
    }

    if (_phase == QrCheckInPhase.recoverableError) {
      return 'Bạn có thể xử lý theo hướng dẫn bên dưới và thử lại ngay trên màn hình này.';
    }

    return null;
  }

  Widget _buildPhaseSummaryCard() {
    final presentation = _phasePresentation();
    final guidance = _phaseGuidance();
    final isLoading =
        _phase == QrCheckInPhase.preparing ||
        _phase == QrCheckInPhase.resolving ||
        _phase == QrCheckInPhase.submitting;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: presentation.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: presentation.color,
                  ),
                )
              else
                Icon(presentation.icon, color: presentation.color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  presentation.title,
                  style: TextStyle(
                    color: presentation.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            presentation.message,
            style: const TextStyle(
              color: _kTextDark,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (guidance != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: presentation.color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guidance,
                      style: const TextStyle(
                        color: _kTextMid,
                        fontSize: 12,
                        height: 1.45,
                      ),
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

  Widget _buildHintPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kBlue, _kCyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sẵn sàng quét',
          style: TextStyle(
            color: _kTextDark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hướng camera vào mã QR điểm danh',
          style: TextStyle(
            color: _kTextMid.withValues(alpha: 0.85),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _buildPhaseSummaryCard(),
      ],
    );
  }

  Widget _buildResultPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // QR confirmed chip
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _kBlueLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBlueSky.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_rounded, color: _kBlue, size: 14),
              SizedBox(width: 6),
              Text(
                'Đã quét mã QR',
                style: TextStyle(
                  color: _kBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        _buildPhaseSummaryCard(),
        if (_capturedLocation != null &&
            _phase != QrCheckInPhase.submitting &&
            _phase != QrCheckInPhase.succeeded)
          _buildStatusRow(
            icon: Icons.my_location_rounded,
            text: 'Đã lấy được vị trí hiện tại. Có thể tiếp tục điểm danh.',
            color: _kSuccess,
          ),
        if (_phase == QrCheckInPhase.faceRequired && !_isCapturingFace)
          _buildPrimaryActionButton(
            label: 'Mở camera trước',
            onTap: _retryCheckIn,
            color: _kBlue,
          ),
        if (_phase == QrCheckInPhase.recoverableError &&
            _locationErrorMessage != null)
          _buildLocationErrorPanel(),
        if (_phase == QrCheckInPhase.recoverableError &&
            _faceCaptureErrorMessage != null)
          _buildFaceRetryPanel(),
        if (_phase == QrCheckInPhase.recoverableError &&
            _locationErrorMessage == null &&
            _faceCaptureErrorMessage == null &&
            _checkInErrorMessage != null)
          _buildCheckInErrorPanel(isHardError: false),
        if (_phase == QrCheckInPhase.hardError && _checkInErrorMessage != null)
          _buildCheckInErrorPanel(isHardError: true),
        if (_phase == QrCheckInPhase.resolving && _capturedLocation != null)
          _buildStatusRow(
            icon: Icons.sync_rounded,
            text: 'Đã đủ dữ liệu. Ứng dụng đang chuẩn bị gửi điểm danh...',
            color: _kBlueMid,
            isLoading: true,
          ),

        const SizedBox(height: 12),

        // Scan again
        GestureDetector(
          onTap: _scanAgain,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: _kBlueLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBlueSky.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: _kBlue, size: 17),
                SizedBox(width: 8),
                Text(
                  'Quét mã QR khác',
                  style: TextStyle(
                    color: _kBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String text,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceRetryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow(
          icon: Icons.camera_front_rounded,
          text: _faceCaptureErrorMessage!,
          color: _kWarn,
        ),
        _buildPrimaryActionButton(
          label: 'Chụp lại ảnh khuôn mặt',
          onTap: _retryCheckIn,
          color: _kBlue,
        ),
      ],
    );
  }

  Widget _buildCheckInErrorPanel({required bool isHardError}) {
    final color = isHardError ? _kError : _kWarn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow(
          icon: isHardError
              ? Icons.block_rounded
              : Icons.error_outline_rounded,
          text: _checkInErrorTitle ?? 'Lỗi điểm danh',
          color: color,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _checkInErrorMessage!,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
        if (!isHardError)
          _buildPrimaryActionButton(
            label: _isCheckInRateLimited
                ? RateLimitPolicy.retryLabel(seconds: _checkInCooldownSeconds)
                : 'Thử lại điểm danh',
            onTap: _isCheckInRateLimited ? null : _retryCheckIn,
            color: _isCheckInRateLimited ? _kTextMid : _kBlue,
            backgroundColor: _isCheckInRateLimited ? _kBlueLight : _kErrorBg,
          ),
      ],
    );
  }

  Widget _buildPrimaryActionButton({
    required String label,
    required VoidCallback? onTap,
    required Color color,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.7 : 1,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 2, bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor ?? _kBlueLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
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

  Widget _buildLocationErrorPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow(
          icon: Icons.location_off_rounded,
          text: _locationErrorMessage ?? 'Không lấy được vị trí',
          color: _kWarn,
        ),
        const SizedBox(height: 6),
        if (_locationIssueType == _LocationIssueType.permissionDenied ||
            _locationIssueType == _LocationIssueType.unknown)
          _SmallButton(label: 'Thử lại', onTap: _retryLocationCapture),
        if (_locationIssueType == _LocationIssueType.permissionBlocked)
          _SmallButton(
            label: 'Mở cài đặt quyền vị trí',
            onTap: () => widget.locationPermissionService.openSettings(),
          ),
        if (_locationIssueType == _LocationIssueType.serviceDisabled)
          _SmallButton(
            label: 'Mở cài đặt GPS',
            onTap: () => widget.locationService.openLocationSettings(),
          ),
      ],
    );
  }

  // Permission screen ──────────────────────────────────────────────────────
  Widget _buildPermissionDeniedScreen() {
    final state = _cameraPermissionState;
    final isPermanent =
        state == CameraPermissionState.permanentlyDenied ||
        state == CameraPermissionState.restricted;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kBlueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: _kBlue,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _kBlueLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kBlueSky.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: _kBlue,
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cần quyền Camera',
                style: TextStyle(
                  color: _kTextDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isPermanent
                    ? 'Quyền camera đang bị chặn. Vui lòng mở cài đặt để cấp quyền.'
                    : 'Cần cấp quyền camera để quét mã QR điểm danh.',
                style: const TextStyle(
                  color: _kTextMid,
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Primary button
              GestureDetector(
                onTap: _requestCameraPermission,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kBlue, _kCyan],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kBlue.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Cấp quyền Camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              if (isPermanent) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => widget.cameraPermissionService.openSettings(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _kBlueLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _kBlueSky.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Mở cài đặt',
                        style: TextStyle(
                          color: _kBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Vignette with cutout ─────────────────────────────────────────────────────
class _VignettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const holeW = 248.0;
    const holeH = 248.0;
    final holeL = (size.width - holeW) / 2;
    final holeT = (size.height - holeH) / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(holeL, holeT, holeW, holeH),
          const Radius.circular(20),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_VignettePainter _) => false;
}

// ─── Scan Corner ─────────────────────────────────────────────────────────────
class _ScanCorner extends StatelessWidget {
  const _ScanCorner({required this.alignment});
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    height: 28,
    child: CustomPaint(painter: _CornerPainter(alignment: alignment)),
  );
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.alignment});
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kCyan
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    final double x = isLeft ? 0 : size.width;
    final double y = isTop ? 0 : size.height;
    final double dx = isLeft ? size.width * 0.65 : -size.width * 0.65;
    final double dy = isTop ? size.height * 0.65 : -size.height * 0.65;
    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Small Button ─────────────────────────────────────────────────────────────
class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _kBlueLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBlueSky.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _kBlue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────
enum _LocationIssueType {
  permissionDenied,
  permissionBlocked,
  serviceDisabled,
  unknown,
}

class _QrPhasePresentation {
  const _QrPhasePresentation({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}
