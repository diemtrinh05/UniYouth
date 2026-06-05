import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/device/check_in_client_device_id_service.dart';
import '../../../../../../core/device/check_in_device_info_service.dart';
import '../../../../../../core/error/app_error.dart';
import '../../../../../../core/error/attendance_error_mapper.dart';
import '../../../../../../core/error/error_presenter.dart';
import '../../../../../../core/location/location_service.dart';
import '../../../../../../core/network/retry_policy/rate_limit_policy.dart';
import '../../../../../../core/permissions/camera_permission_service.dart';
import '../../../../../../core/permissions/location_permission_service.dart';
import '../../../../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../../../../domain/usecases/attendance/get_check_in_requirements_usecase.dart';
import '../../face_capture/attendance_face_capture_service.dart';
import 'qr_check_in_state.dart';

class QrCheckInNotifier extends StateNotifier<QrCheckInState> {
  QrCheckInNotifier({
    required CameraPermissionService cameraPermissionService,
    required LocationPermissionService locationPermissionService,
    required LocationService locationService,
    required CheckInDeviceInfoService deviceInfoService,
    required CheckInClientDeviceIdService clientDeviceIdService,
    required CheckInUseCase checkInUseCase,
    required GetCheckInRequirementsUseCase getCheckInRequirementsUseCase,
    required bool enableFaceVerification,
  }) : _cameraPermissionService = cameraPermissionService,
       _locationPermissionService = locationPermissionService,
       _locationService = locationService,
       _deviceInfoService = deviceInfoService,
       _clientDeviceIdService = clientDeviceIdService,
       _checkInUseCase = checkInUseCase,
       _getCheckInRequirementsUseCase = getCheckInRequirementsUseCase,
       super(QrCheckInState(requiresFaceCapture: enableFaceVerification));

  static const Duration _scanCooldown = Duration(seconds: 2);
  final CameraPermissionService _cameraPermissionService;
  final LocationPermissionService _locationPermissionService;
  final LocationService _locationService;
  final CheckInDeviceInfoService _deviceInfoService;
  final CheckInClientDeviceIdService _clientDeviceIdService;
  final CheckInUseCase _checkInUseCase;
  final GetCheckInRequirementsUseCase _getCheckInRequirementsUseCase;

  Timer? _checkInCooldownTimer;
  DateTime? _lastScanTime;
  bool _isDisposed = false;

  Future<void> initCameraPermission() async {
    final currentState = await _cameraPermissionService.checkPermission();
    var resolvedState = currentState;
    if (currentState != CameraPermissionState.granted) {
      resolvedState = await _cameraPermissionService.requestPermission();
    }
    _setState(
      state.copyWith(
        cameraPermissionState: resolvedState,
        isCheckingCameraPermission: false,
      ),
    );
  }

  Future<void> requestCameraPermission() async {
    _setState(state.copyWith(isCheckingCameraPermission: true));
    final permissionState = await _cameraPermissionService.requestPermission();
    _setState(
      state.copyWith(
        cameraPermissionState: permissionState,
        isCheckingCameraPermission: false,
      ),
    );
  }

  Future<bool> handleQrTokenDetected(String? rawToken) async {
    if (state.isHandlingScan || state.hasScannedToken) {
      return false;
    }

    final token = rawToken?.trim();
    if (token == null || token.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < _scanCooldown) {
      return false;
    }
    _lastScanTime = now;

    _setState(state.copyWith(isHandlingScan: true));
    try {
      _setState(state.copyWith(scannedQrToken: token));
      await _resolveCheckInRequirements(token);
      await _captureLocationAtScanTime();
      return true;
    } on AppError catch (error) {
      final mapped = AttendanceErrorMapper.mapCheckInError(error);
      _setState(
        state.copyWith(
          clearCapturedLocation: true,
          clearCapturedFaceEvidence: true,
          checkInErrorTitle: mapped.title,
          checkInErrorMessage: mapped.message,
          errorSeverity: QrCheckInErrorSeverity.hard,
        ),
      );
      return true;
    } on FormatException catch (_) {
      final presented = ErrorPresenter.presentException(
        operation: 'lấy yêu cầu điểm danh',
      );
      _setState(
        state.copyWith(
          clearCapturedLocation: true,
          clearCapturedFaceEvidence: true,
          checkInErrorTitle: presented.title,
          checkInErrorMessage: presented.message,
          errorSeverity: QrCheckInErrorSeverity.hard,
          feedbackMessage: presented.message,
        ),
      );
      return true;
    } finally {
      _setState(state.copyWith(isHandlingScan: false));
    }
  }

  Future<void> _resolveCheckInRequirements(String qrToken) async {
    final requirements = await _getCheckInRequirementsUseCase(qrToken: qrToken);
    _setState(
        state.copyWith(
          requiresFaceCapture: requirements.enableFaceVerification,
          isAwaitingFaceCapture: false,
          clearCapturedFaceEvidence: !requirements.enableFaceVerification,
          clearFaceCaptureErrorMessage: true,
          clearErrorSeverity: true,
        ),
      );
  }

  Future<void> retryLocationCapture() async {
    if (!state.hasScannedToken || state.isResolvingLocation) {
      return;
    }
    await _captureLocationAtScanTime();
  }

  Future<void> retryCheckIn() async {
    final location = state.capturedLocation;
    if (location == null ||
        state.isResolvingLocation ||
        state.isSubmittingCheckIn ||
        state.isCheckInRateLimited) {
      return;
    }
    if (state.requiresFaceCapture && state.capturedFaceEvidence == null) {
      _setState(
        state.copyWith(
          isAwaitingFaceCapture: true,
          clearFaceCaptureErrorMessage: true,
          clearFeedbackMessage: true,
          clearErrorSeverity: true,
        ),
      );
      return;
    }
    await _submitCheckIn(location);
  }

  Future<void> completeFaceCapture(
    CapturedFaceEvidence capturedFaceEvidence,
  ) async {
    final location = state.capturedLocation;
    if (!state.hasScannedToken || location == null) {
      return;
    }

    _setState(
      state.copyWith(
        isAwaitingFaceCapture: false,
        capturedFaceEvidence: capturedFaceEvidence,
        clearFaceCaptureErrorMessage: true,
        clearFeedbackMessage: true,
        clearErrorSeverity: true,
      ),
    );
    await _submitCheckIn(location);
  }

  void cancelFaceCapture() {
    if (!state.requiresFaceCapture) {
      return;
    }

    _setState(
      state.copyWith(
        isAwaitingFaceCapture: false,
        faceCaptureErrorMessage:
            'Bạn chưa hoàn tất quét khuôn mặt bằng camera trước.',
        errorSeverity: QrCheckInErrorSeverity.recoverable,
      ),
    );
  }

  void resetScanSession() {
    if (state.cameraPermissionState != CameraPermissionState.granted) {
      return;
    }
    _setState(
      state.copyWith(
        clearScannedQrToken: true,
        clearCapturedLocation: true,
        isAwaitingFaceCapture: false,
        clearCapturedFaceEvidence: true,
        clearFaceCaptureErrorMessage: true,
        clearLocationIssueType: true,
        clearLocationErrorMessage: true,
        isResolvingLocation: false,
        isSubmittingCheckIn: false,
        clearCheckInResult: true,
        clearCheckInErrorTitle: true,
        clearCheckInErrorMessage: true,
        clearFeedbackMessage: true,
        clearErrorSeverity: true,
      ),
    );
  }

  Future<void> _captureLocationAtScanTime() async {
    _setState(
      state.copyWith(
        isResolvingLocation: true,
        clearCapturedLocation: true,
        isAwaitingFaceCapture: false,
        clearCapturedFaceEvidence: true,
        clearFaceCaptureErrorMessage: true,
        clearLocationIssueType: true,
        clearLocationErrorMessage: true,
        clearCheckInResult: true,
        clearCheckInErrorTitle: true,
        clearCheckInErrorMessage: true,
        clearFeedbackMessage: true,
        clearErrorSeverity: true,
      ),
    );

    _LocationCaptureResult result;
    try {
      result = await _resolveLocation();
    } catch (_) {
      result = const _LocationCaptureResult(
        issueType: QrLocationIssueType.unknown,
        message: 'Không lấy được tọa độ tại thời điểm quét.',
      );
    }

    _setState(
      state.copyWith(
        isResolvingLocation: false,
        capturedLocation: result.location,
        locationIssueType: result.issueType,
        locationErrorMessage: result.message,
        errorSeverity: result.location == null && result.message != null
            ? QrCheckInErrorSeverity.recoverable
            : null,
      ),
    );

    if (result.location != null) {
      if (state.requiresFaceCapture && state.capturedFaceEvidence == null) {
        _setState(
          state.copyWith(
            isAwaitingFaceCapture: true,
            clearFaceCaptureErrorMessage: true,
          ),
        );
        return;
      }
      await _submitCheckIn(result.location!);
      return;
    }

    if (result.issueType == QrLocationIssueType.unknown) {
      _setState(
        state.copyWith(
          feedbackMessage: result.message ?? 'Không lấy được vị trí hiện tại.',
        ),
      );
    }
  }

  Future<_LocationCaptureResult> _resolveLocation() async {
    var permissionState = await _locationPermissionService
        .checkPermission()
        .timeout(const Duration(seconds: 10));

    if (permissionState != LocationPermissionState.granted) {
      permissionState = await _locationPermissionService
          .requestPermission()
          .timeout(const Duration(seconds: 10));
    }

    if (permissionState != LocationPermissionState.granted) {
      if (permissionState == LocationPermissionState.permanentlyDenied ||
          permissionState == LocationPermissionState.restricted) {
        return const _LocationCaptureResult(
          issueType: QrLocationIssueType.permissionBlocked,
          message:
              'Quyền vị trí đang bị chặn. Vui lòng mở cài đặt để cấp quyền.',
        );
      }
      return const _LocationCaptureResult(
        issueType: QrLocationIssueType.permissionDenied,
        message: 'Bạn đã từ chối quyền vị trí.',
      );
    }

    final serviceEnabled = await _locationService
        .isLocationServiceEnabled()
        .timeout(const Duration(seconds: 10));
    if (!serviceEnabled) {
      return const _LocationCaptureResult(
        issueType: QrLocationIssueType.serviceDisabled,
        message: 'GPS đang tắt. Vui lòng bật GPS để tiếp tục.',
      );
    }

    try {
      final location = await _locationService.getCurrentLocation();
      return _LocationCaptureResult(location: location);
    } catch (_) {
      return const _LocationCaptureResult(
        issueType: QrLocationIssueType.unknown,
        message: 'Không lấy được tọa độ tại thời điểm quét.',
      );
    }
  }

  Future<void> _submitCheckIn(GeoLocationPoint location) async {
    final token = state.scannedQrToken;
    if (token == null ||
        state.isSubmittingCheckIn ||
        state.isCheckInRateLimited) {
      return;
    }

    _setState(
      state.copyWith(
        isSubmittingCheckIn: true,
        clearCheckInResult: true,
        clearCheckInErrorTitle: true,
        clearCheckInErrorMessage: true,
        clearFeedbackMessage: true,
        clearErrorSeverity: true,
      ),
    );

    try {
      final deviceInfo = await _deviceInfoService.buildDeviceInfo();
      final clientDeviceId = await _clientDeviceIdService.getClientDeviceId();
      final capturedFaceEvidence = state.capturedFaceEvidence;
      final result = await _checkInUseCase(
        qrToken: token,
        latitude: location.latitude,
        longitude: location.longitude,
        deviceInfo: deviceInfo,
        clientDeviceId: clientDeviceId,
        faceImageBase64: capturedFaceEvidence != null
            ? base64Encode(capturedFaceEvidence.faceImage.bytes)
            : null,
        faceImageMimeType: capturedFaceEvidence?.faceImage.mimeType,
        liveness: capturedFaceEvidence == null
            ? null
            : CheckInLivenessPayload(
                mode: capturedFaceEvidence.liveness.mode,
                frameCount: capturedFaceEvidence.liveness.frameCount,
                mimeType: capturedFaceEvidence.liveness.mimeType,
                frames: capturedFaceEvidence.liveness.frames
                    .map(
                      (frame) => CheckInLivenessFrame(
                        frameIndex: frame.frameIndex,
                        imageBase64: base64Encode(frame.bytes),
                        capturedAtMs: frame.capturedAtMs,
                      ),
                    )
                    .toList(growable: false),
              ),
      );
      _setState(state.copyWith(checkInResult: result));
    } on AppError catch (error) {
      if (error.statusCode == 429) {
        _startCheckInCooldown();
        final message = RateLimitPolicy.cooldownMessage(
          seconds: state.checkInCooldownSeconds,
          backendMessage: error.message,
        );
        _setState(
          state.copyWith(
            checkInErrorTitle: 'Thao tác quá nhanh',
            checkInErrorMessage: message,
            errorSeverity: QrCheckInErrorSeverity.recoverable,
          ),
        );
        return;
      }
      final mapped = AttendanceErrorMapper.mapCheckInError(error);
      _setState(
        state.copyWith(
          checkInErrorTitle: mapped.title,
          checkInErrorMessage: mapped.message,
          errorSeverity: _resolveErrorSeverity(mapped.type),
        ),
      );
    } on FormatException catch (_) {
      final presented = ErrorPresenter.presentException(
        operation: 'gửi check-in',
      );
      _setState(
        state.copyWith(
          checkInErrorTitle: presented.title,
          checkInErrorMessage: presented.message,
          errorSeverity: QrCheckInErrorSeverity.recoverable,
          feedbackMessage: presented.message,
        ),
      );
    } finally {
      _setState(state.copyWith(isSubmittingCheckIn: false));
    }
  }

  void clearFeedbackMessage() {
    if (state.feedbackMessage == null) {
      return;
    }
    _setState(state.copyWith(clearFeedbackMessage: true));
  }

  void _startCheckInCooldown() {
    final duration = RateLimitPolicy.cooldownFor(
      SensitiveApiAction.attendanceCheckIn,
    );
    _checkInCooldownTimer?.cancel();
    _setState(state.copyWith(checkInCooldownSeconds: duration.inSeconds));

    _checkInCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      final nextSeconds = state.checkInCooldownSeconds - 1;
      if (nextSeconds > 0) {
        _setState(state.copyWith(checkInCooldownSeconds: nextSeconds));
        return;
      }
      timer.cancel();
      _setState(state.copyWith(checkInCooldownSeconds: 0));
    });
  }

  void _setState(QrCheckInState nextState) {
    if (_isDisposed) {
      return;
    }
    state = nextState;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _checkInCooldownTimer?.cancel();
    super.dispose();
  }
}

QrCheckInErrorSeverity _resolveErrorSeverity(AttendanceEdgeCaseType type) {
  switch (type) {
    case AttendanceEdgeCaseType.qrInvalid:
    case AttendanceEdgeCaseType.qrExpired:
    case AttendanceEdgeCaseType.qrNotYetValid:
    case AttendanceEdgeCaseType.qrInactive:
    case AttendanceEdgeCaseType.qrScanLimitExceeded:
    case AttendanceEdgeCaseType.notRegistered:
    case AttendanceEdgeCaseType.registrationCancelled:
    case AttendanceEdgeCaseType.alreadyCheckedIn:
    case AttendanceEdgeCaseType.retryExhausted:
    case AttendanceEdgeCaseType.eventNotOngoing:
    case AttendanceEdgeCaseType.faceProfileMissing:
      return QrCheckInErrorSeverity.hard;
    case AttendanceEdgeCaseType.distanceTooFar:
    case AttendanceEdgeCaseType.faceMismatch:
    case AttendanceEdgeCaseType.faceReview:
    case AttendanceEdgeCaseType.noFaceDetected:
    case AttendanceEdgeCaseType.multipleFacesDetected:
    case AttendanceEdgeCaseType.blurryFaceImage:
    case AttendanceEdgeCaseType.faceInvalidPayload:
    case AttendanceEdgeCaseType.faceTechnicalError:
    case AttendanceEdgeCaseType.unknown:
      return QrCheckInErrorSeverity.recoverable;
  }
}

class _LocationCaptureResult {
  const _LocationCaptureResult({this.location, this.issueType, this.message});

  final GeoLocationPoint? location;
  final QrLocationIssueType? issueType;
  final String? message;
}




