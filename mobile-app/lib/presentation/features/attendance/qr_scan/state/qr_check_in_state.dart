import '../../../../../../core/location/location_service.dart';
import '../../../../../../core/permissions/camera_permission_service.dart';
import '../../../../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../face_capture/attendance_face_capture_service.dart';

enum QrLocationIssueType {
  permissionDenied,
  permissionBlocked,
  serviceDisabled,
  unknown,
}

enum QrCheckInPhase {
  preparing,
  scanning,
  resolving,
  faceRequired,
  submitting,
  succeeded,
  recoverableError,
  hardError,
}

enum QrCheckInErrorSeverity {
  recoverable,
  hard,
}

class QrCheckInState {
  const QrCheckInState({
    this.cameraPermissionState,
    this.isCheckingCameraPermission = true,
    this.requiresFaceCapture = false,
    this.isHandlingScan = false,
    this.scannedQrToken,
    this.isResolvingLocation = false,
    this.capturedLocation,
    this.isAwaitingFaceCapture = false,
    this.capturedFaceEvidence,
    this.faceCaptureErrorMessage,
    this.locationIssueType,
    this.locationErrorMessage,
    this.isSubmittingCheckIn = false,
    this.checkInCooldownSeconds = 0,
    this.checkInResult,
    this.checkInErrorTitle,
    this.checkInErrorMessage,
    this.errorSeverity,
    this.feedbackMessage,
  });

  final CameraPermissionState? cameraPermissionState;
  final bool isCheckingCameraPermission;
  final bool requiresFaceCapture;
  final bool isHandlingScan;

  final String? scannedQrToken;
  final bool isResolvingLocation;
  final GeoLocationPoint? capturedLocation;
  final bool isAwaitingFaceCapture;
  final CapturedFaceEvidence? capturedFaceEvidence;
  final String? faceCaptureErrorMessage;
  final QrLocationIssueType? locationIssueType;
  final String? locationErrorMessage;

  final bool isSubmittingCheckIn;
  final int checkInCooldownSeconds;
  final CheckInResult? checkInResult;
  final String? checkInErrorTitle;
  final String? checkInErrorMessage;
  final QrCheckInErrorSeverity? errorSeverity;

  final String? feedbackMessage;

  bool get isCheckInRateLimited => checkInCooldownSeconds > 0;
  bool get hasScannedToken => (scannedQrToken ?? '').trim().isNotEmpty;
  bool get hasError =>
      (faceCaptureErrorMessage ?? '').trim().isNotEmpty ||
      (locationErrorMessage ?? '').trim().isNotEmpty ||
      (checkInErrorMessage ?? '').trim().isNotEmpty;

  QrCheckInPhase get phase {
    if (isCheckingCameraPermission) {
      return QrCheckInPhase.preparing;
    }
    if (checkInResult != null) {
      return QrCheckInPhase.succeeded;
    }
    if (isSubmittingCheckIn) {
      return QrCheckInPhase.submitting;
    }
    if (isAwaitingFaceCapture) {
      return QrCheckInPhase.faceRequired;
    }
    if (isHandlingScan || isResolvingLocation) {
      return QrCheckInPhase.resolving;
    }
    if (hasError) {
      return errorSeverity == QrCheckInErrorSeverity.hard
          ? QrCheckInPhase.hardError
          : QrCheckInPhase.recoverableError;
    }
    if (!hasScannedToken) {
      return cameraPermissionState == CameraPermissionState.granted
          ? QrCheckInPhase.scanning
          : QrCheckInPhase.preparing;
    }
    return capturedLocation != null
        ? QrCheckInPhase.resolving
        : QrCheckInPhase.preparing;
  }

  QrCheckInState copyWith({
    CameraPermissionState? cameraPermissionState,
    bool clearCameraPermissionState = false,
    bool? isCheckingCameraPermission,
    bool? requiresFaceCapture,
    bool? isHandlingScan,
    String? scannedQrToken,
    bool clearScannedQrToken = false,
    bool? isResolvingLocation,
    GeoLocationPoint? capturedLocation,
    bool clearCapturedLocation = false,
    bool? isAwaitingFaceCapture,
    CapturedFaceEvidence? capturedFaceEvidence,
    bool clearCapturedFaceEvidence = false,
    String? faceCaptureErrorMessage,
    bool clearFaceCaptureErrorMessage = false,
    QrLocationIssueType? locationIssueType,
    bool clearLocationIssueType = false,
    String? locationErrorMessage,
    bool clearLocationErrorMessage = false,
    bool? isSubmittingCheckIn,
    int? checkInCooldownSeconds,
    CheckInResult? checkInResult,
    bool clearCheckInResult = false,
    String? checkInErrorTitle,
    bool clearCheckInErrorTitle = false,
    String? checkInErrorMessage,
    bool clearCheckInErrorMessage = false,
    QrCheckInErrorSeverity? errorSeverity,
    bool clearErrorSeverity = false,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return QrCheckInState(
      cameraPermissionState: clearCameraPermissionState
          ? null
          : (cameraPermissionState ?? this.cameraPermissionState),
      isCheckingCameraPermission:
          isCheckingCameraPermission ?? this.isCheckingCameraPermission,
      requiresFaceCapture: requiresFaceCapture ?? this.requiresFaceCapture,
      isHandlingScan: isHandlingScan ?? this.isHandlingScan,
      scannedQrToken: clearScannedQrToken
          ? null
          : (scannedQrToken ?? this.scannedQrToken),
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      capturedLocation: clearCapturedLocation
          ? null
          : (capturedLocation ?? this.capturedLocation),
      isAwaitingFaceCapture:
          isAwaitingFaceCapture ?? this.isAwaitingFaceCapture,
      capturedFaceEvidence: clearCapturedFaceEvidence
          ? null
          : (capturedFaceEvidence ?? this.capturedFaceEvidence),
      faceCaptureErrorMessage: clearFaceCaptureErrorMessage
          ? null
          : (faceCaptureErrorMessage ?? this.faceCaptureErrorMessage),
      locationIssueType: clearLocationIssueType
          ? null
          : (locationIssueType ?? this.locationIssueType),
      locationErrorMessage: clearLocationErrorMessage
          ? null
          : (locationErrorMessage ?? this.locationErrorMessage),
      isSubmittingCheckIn: isSubmittingCheckIn ?? this.isSubmittingCheckIn,
      checkInCooldownSeconds:
          checkInCooldownSeconds ?? this.checkInCooldownSeconds,
      checkInResult: clearCheckInResult
          ? null
          : (checkInResult ?? this.checkInResult),
      checkInErrorTitle: clearCheckInErrorTitle
          ? null
          : (checkInErrorTitle ?? this.checkInErrorTitle),
      checkInErrorMessage: clearCheckInErrorMessage
          ? null
          : (checkInErrorMessage ?? this.checkInErrorMessage),
      errorSeverity: clearErrorSeverity
          ? null
          : (errorSeverity ?? this.errorSeverity),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }
}
