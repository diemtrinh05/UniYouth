import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/device/check_in_client_device_id_service.dart';
import 'package:uniyouth_app/core/device/check_in_device_info_service.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/core/location/location_service.dart';
import 'package:uniyouth_app/core/permissions/camera_permission_service.dart';
import 'package:uniyouth_app/core/permissions/location_permission_service.dart';
import 'package:uniyouth_app/domain/usecases/attendance/check_in_usecase.dart';
import 'package:uniyouth_app/domain/usecases/attendance/get_check_in_requirements_usecase.dart';
import 'package:uniyouth_app/presentation/features/attendance/face_capture/attendance_face_capture_service.dart';
import 'package:uniyouth_app/presentation/features/attendance/qr_scan/state/qr_check_in_notifier.dart';
import 'package:uniyouth_app/presentation/features/attendance/qr_scan/state/qr_check_in_state.dart';

void main() {
  group('QrCheckInNotifier', () {
    test(
      'initCameraPermission requests permission when current state is denied',
      () async {
        final cameraService = _FakeCameraPermissionService(
          checkResult: CameraPermissionState.denied,
          requestResult: CameraPermissionState.granted,
        );
        final notifier = _createNotifier(
          cameraPermissionService: cameraService,
        );
        addTearDown(notifier.dispose);

        await notifier.initCameraPermission();

        expect(cameraService.checkCallCount, 1);
        expect(cameraService.requestCallCount, 1);
        expect(
          notifier.state.cameraPermissionState,
          CameraPermissionState.granted,
        );
        expect(notifier.state.isCheckingCameraPermission, isFalse);
      },
    );

    test(
      'handleQrTokenDetected sets location issue when permission is denied',
      () async {
        final notifier = _createNotifier(
          locationPermissionService: _FakeLocationPermissionService(
            checkResult: LocationPermissionState.denied,
            requestResult: LocationPermissionState.denied,
          ),
        );
        addTearDown(notifier.dispose);

        final handled = await notifier.handleQrTokenDetected('  qr-token  ');

        expect(handled, isTrue);
        expect(notifier.state.scannedQrToken, 'qr-token');
        expect(
          notifier.state.locationIssueType,
          QrLocationIssueType.permissionDenied,
        );
        expect(notifier.state.feedbackMessage, isNull);
        expect(notifier.state.checkInResult, isNull);
      },
    );

    test('handleQrTokenDetected performs check-in successfully', () async {
      String? capturedDeviceInfo;
      String? capturedClientDeviceId;
      final checkInRepository = _FakeCheckInRepository(
        onCheckIn:
            ({
              required qrToken,
              required latitude,
              required longitude,
              required deviceInfo,
              required clientDeviceId,
              required faceImageBase64,
              required faceImageMimeType,
              required liveness,
            }) async {
              capturedDeviceInfo = deviceInfo;
              capturedClientDeviceId = clientDeviceId;
              return _checkInResult(success: true);
            },
      );
      final notifier = _createNotifier(
        locationPermissionService: _FakeLocationPermissionService(
          checkResult: LocationPermissionState.granted,
          requestResult: LocationPermissionState.granted,
        ),
        locationService: _FakeLocationService(
          isServiceEnabled: true,
          location: GeoLocationPoint(
            latitude: 10.5,
            longitude: 106.7,
            capturedAt: DateTime(2026, 1, 1),
          ),
        ),
        checkInUseCase: CheckInUseCase(repository: checkInRepository),
      );
      addTearDown(notifier.dispose);

      final handled = await notifier.handleQrTokenDetected('qr-123');

      expect(handled, isTrue);
      expect(checkInRepository.checkInCallCount, 1);
      expect(capturedDeviceInfo, 'Android 14 | Pixel 8 | UniYouth 1.0.0');
      expect(capturedClientDeviceId, '8d5b8ec0-0d66-4ad7-b6f0-f95c90d5d010');
      expect(notifier.state.checkInResult?.isSuccess, isTrue);
      expect(notifier.state.isSubmittingCheckIn, isFalse);
      expect(notifier.state.checkInErrorMessage, isNull);
    });

    test('completeFaceCapture submits liveness payload', () async {
      String? capturedFaceImageBase64;
      String? capturedFaceImageMimeType;
      CheckInLivenessPayload? capturedLiveness;

      final checkInRepository = _FakeCheckInRepository(
        onCheckIn:
            ({
              required qrToken,
              required latitude,
              required longitude,
              required deviceInfo,
              required clientDeviceId,
              required faceImageBase64,
              required faceImageMimeType,
              required liveness,
            }) async {
              capturedFaceImageBase64 = faceImageBase64;
              capturedFaceImageMimeType = faceImageMimeType;
              capturedLiveness = liveness;
              return _checkInResult(success: true);
            },
      );

      final notifier = _createNotifier(
        locationPermissionService: _FakeLocationPermissionService(
          checkResult: LocationPermissionState.granted,
          requestResult: LocationPermissionState.granted,
        ),
        locationService: _FakeLocationService(
          isServiceEnabled: true,
          location: GeoLocationPoint(
            latitude: 10.5,
            longitude: 106.7,
            capturedAt: DateTime(2026, 1, 1),
          ),
        ),
        checkInUseCase: CheckInUseCase(repository: checkInRepository),
        enableFaceVerification: true,
      );
      addTearDown(notifier.dispose);

      final handled = await notifier.handleQrTokenDetected('qr-face');

      expect(handled, isTrue);
      expect(notifier.state.isAwaitingFaceCapture, isTrue);
      expect(checkInRepository.checkInCallCount, 0);

      await notifier.completeFaceCapture(_capturedFaceEvidence());

      expect(checkInRepository.checkInCallCount, 1);
      expect(capturedFaceImageBase64, isNotNull);
      expect(capturedFaceImageMimeType, 'image/jpeg');
      expect(capturedLiveness?.mode, 'passive_auto_burst');
      expect(capturedLiveness?.frameCount, 3);
      expect(capturedLiveness?.mimeType, 'image/jpeg');
      expect(capturedLiveness?.frames.length, 3);
      expect(capturedLiveness?.frames.first.frameIndex, 0);
      expect(capturedLiveness?.frames.last.frameIndex, 2);
    });

    test(
      'handleQrTokenDetected sets cooldown when check-in returns 429',
      () async {
        final checkInRepository = _FakeCheckInRepository(
          onCheckIn:
              ({
                required qrToken,
                required latitude,
                required longitude,
                required deviceInfo,
                required clientDeviceId,
                required faceImageBase64,
                required faceImageMimeType,
                required liveness,
              }) async {
                throw const AppError(
                  type: AppErrorType.tooManyRequests,
                  statusCode: 429,
                  message: 'Too many requests',
                );
              },
        );
        final notifier = _createNotifier(
          locationPermissionService: _FakeLocationPermissionService(
            checkResult: LocationPermissionState.granted,
            requestResult: LocationPermissionState.granted,
          ),
          locationService: _FakeLocationService(
            isServiceEnabled: true,
            location: GeoLocationPoint(
              latitude: 10.5,
              longitude: 106.7,
              capturedAt: DateTime(2026, 1, 1),
            ),
          ),
          checkInUseCase: CheckInUseCase(repository: checkInRepository),
        );
        addTearDown(notifier.dispose);

        await notifier.handleQrTokenDetected('qr-429');

        expect(notifier.state.isCheckInRateLimited, isTrue);
        expect(notifier.state.checkInCooldownSeconds, greaterThan(0));
        expect(notifier.state.checkInErrorTitle, 'Thao tác quá nhanh');
        expect(notifier.state.feedbackMessage, isNull);
      },
    );


    test('handleQrTokenDetected maps QR invalid requirement error to panel state', () async {
      final notifier = _createNotifier(
        getCheckInRequirementsUseCase: GetCheckInRequirementsUseCase(
          repository: _FakeCheckInRequirementsRepository(
            enableFaceVerification: false,
            appError: const AppError(
              type: AppErrorType.notFound,
              statusCode: 404,
              message:
                  '[ATTENDANCE_QR_NOT_FOUND] Mã QR không tồn tại hoặc đã bị thu hồi',
            ),
          ),
        ),
      );
      addTearDown(notifier.dispose);

      final handled = await notifier.handleQrTokenDetected('qr-invalid');

      expect(handled, isTrue);
      expect(notifier.state.checkInErrorTitle, 'QR không hợp lệ');
      expect(
        notifier.state.checkInErrorMessage,
        'Mã QR không tồn tại, đã bị thu hồi hoặc không còn dùng được.',
      );
      expect(notifier.state.feedbackMessage, isNull);
      expect(notifier.state.capturedLocation, isNull);
    });
  });
}

QrCheckInNotifier _createNotifier({
  CameraPermissionService? cameraPermissionService,
  LocationPermissionService? locationPermissionService,
  LocationService? locationService,
  CheckInDeviceInfoService? deviceInfoService,
  CheckInClientDeviceIdService? clientDeviceIdService,
  CheckInUseCase? checkInUseCase,
  GetCheckInRequirementsUseCase? getCheckInRequirementsUseCase,
  bool enableFaceVerification = false,
}) {
  return QrCheckInNotifier(
    cameraPermissionService:
        cameraPermissionService ??
        _FakeCameraPermissionService(
          checkResult: CameraPermissionState.granted,
          requestResult: CameraPermissionState.granted,
        ),
    locationPermissionService:
        locationPermissionService ??
        _FakeLocationPermissionService(
          checkResult: LocationPermissionState.granted,
          requestResult: LocationPermissionState.granted,
        ),
    locationService:
        locationService ??
        _FakeLocationService(
          isServiceEnabled: true,
          location: GeoLocationPoint(
            latitude: 10.0,
            longitude: 106.0,
            capturedAt: DateTime(2026, 1, 1),
          ),
        ),
    deviceInfoService:
        deviceInfoService ??
        const _FakeCheckInDeviceInfoService(
          deviceInfo: 'Android 14 | Pixel 8 | UniYouth 1.0.0',
        ),
    clientDeviceIdService:
        clientDeviceIdService ??
        const _FakeCheckInClientDeviceIdService(
          clientDeviceId: '8d5b8ec0-0d66-4ad7-b6f0-f95c90d5d010',
        ),
    checkInUseCase:
        checkInUseCase ??
        CheckInUseCase(
          repository: _FakeCheckInRepository(
            onCheckIn:
                ({
                  required qrToken,
                  required latitude,
                  required longitude,
                  required deviceInfo,
                  required clientDeviceId,
                  required faceImageBase64,
                  required faceImageMimeType,
                  required liveness,
                }) async => _checkInResult(success: true),
          ),
        ),
    getCheckInRequirementsUseCase:
        getCheckInRequirementsUseCase ??
        GetCheckInRequirementsUseCase(
          repository: _FakeCheckInRequirementsRepository(
            enableFaceVerification: enableFaceVerification,
          ),
        ),
    enableFaceVerification: enableFaceVerification,
  );
}

class _FakeCameraPermissionService implements CameraPermissionService {
  _FakeCameraPermissionService({
    required this.checkResult,
    required this.requestResult,
  });

  final CameraPermissionState checkResult;
  final CameraPermissionState requestResult;
  int checkCallCount = 0;
  int requestCallCount = 0;

  @override
  Future<CameraPermissionState> checkPermission() async {
    checkCallCount += 1;
    return checkResult;
  }

  @override
  Future<CameraPermissionState> requestPermission() async {
    requestCallCount += 1;
    return requestResult;
  }

  @override
  Future<bool> openSettings() async => true;
}

class _FakeLocationPermissionService implements LocationPermissionService {
  _FakeLocationPermissionService({
    required this.checkResult,
    required this.requestResult,
  });

  final LocationPermissionState checkResult;
  final LocationPermissionState requestResult;

  @override
  Future<LocationPermissionState> checkPermission() async => checkResult;

  @override
  Future<LocationPermissionState> requestPermission() async => requestResult;

  @override
  Future<bool> openSettings() async => true;
}

class _FakeLocationService implements LocationService {
  _FakeLocationService({
    required this.isServiceEnabled,
    required this.location,
  });

  final bool isServiceEnabled;
  final GeoLocationPoint location;

  @override
  Future<GeoLocationPoint> getCurrentLocation() async => location;

  @override
  Future<bool> isLocationServiceEnabled() async => isServiceEnabled;

  @override
  Future<bool> openLocationSettings() async => true;
}

class _FakeCheckInRepository implements CheckInRepository {
  _FakeCheckInRepository({required this.onCheckIn});

  final Future<CheckInResult> Function({
    required String qrToken,
    required double latitude,
    required double longitude,
    required String? deviceInfo,
    required String? clientDeviceId,
    required String? faceImageBase64,
    required String? faceImageMimeType,
    required CheckInLivenessPayload? liveness,
  })
  onCheckIn;

  int checkInCallCount = 0;

  @override
  Future<CheckInResult> checkIn({
    required String qrToken,
    required double latitude,
    required double longitude,
    String? deviceInfo,
    String? clientDeviceId,
    String? faceImageBase64,
    String? faceImageMimeType,
    CheckInLivenessPayload? liveness,
  }) async {
    checkInCallCount += 1;
    return onCheckIn(
      qrToken: qrToken,
      latitude: latitude,
      longitude: longitude,
      deviceInfo: deviceInfo,
      clientDeviceId: clientDeviceId,
      faceImageBase64: faceImageBase64,
      faceImageMimeType: faceImageMimeType,
      liveness: liveness,
    );
  }
}

class _FakeCheckInRequirementsRepository
    implements CheckInRequirementsRepository {
  _FakeCheckInRequirementsRepository({
    required this.enableFaceVerification,
    this.appError,
  });

  final bool enableFaceVerification;
  final AppError? appError;

  @override
  Future<CheckInRequirements> getCheckInRequirements({
    required String qrToken,
  }) async {
    if (appError != null) {
      throw appError!;
    }
    return CheckInRequirements(
      eventId: 1,
      eventName: 'Test Event',
      enableFaceVerification: enableFaceVerification,
    );
  }
}

class _FakeCheckInDeviceInfoService implements CheckInDeviceInfoService {
  const _FakeCheckInDeviceInfoService({required this.deviceInfo});

  final String? deviceInfo;

  @override
  Future<String?> buildDeviceInfo() async => deviceInfo;
}

class _FakeCheckInClientDeviceIdService
    implements CheckInClientDeviceIdService {
  const _FakeCheckInClientDeviceIdService({required this.clientDeviceId});

  final String? clientDeviceId;

  @override
  Future<String?> getClientDeviceId() async => clientDeviceId;
}

CheckInResult _checkInResult({required bool success}) {
  return CheckInResult(
    isValid: success,
    invalidReason: null,
    distance: success ? 1.0 : 150.0,
    pointsAwarded: const CheckInPointsAwarded(
      points: 10,
      pointType: 'attendance',
      roleType: 'member',
      currentTotalPoints: 100,
    ),
    isSuccess: success,
    message: success ? 'Checked in' : 'Failed',
    eventName: 'Test Event',
    checkInTime: DateTime(2026, 1, 1, 8, 0, 0),
    attendanceId: success ? 123 : null,
    faceVerified: null,
    faceConfidence: null,
    faceVerificationStatus: null,
    faceVerificationMessage: null,
    riskScore: null,
    riskLevel: null,
  );
}

CapturedFaceEvidence _capturedFaceEvidence() {
  return const CapturedFaceEvidence(
    faceImage: CapturedFaceImage(
      bytes: <int>[1, 2, 3, 4],
      mimeType: 'image/jpeg',
      fileName: 'face.jpg',
    ),
    liveness: CapturedLivenessPayload(
      mode: 'passive_auto_burst',
      frameCount: 3,
      mimeType: 'image/jpeg',
      frames: <CapturedLivenessFrame>[
        CapturedLivenessFrame(
          frameIndex: 0,
          capturedAtMs: 0,
          bytes: <int>[1, 2, 3],
        ),
        CapturedLivenessFrame(
          frameIndex: 1,
          capturedAtMs: 350,
          bytes: <int>[4, 5, 6],
        ),
        CapturedLivenessFrame(
          frameIndex: 2,
          capturedAtMs: 700,
          bytes: <int>[7, 8, 9],
        ),
      ],
    ),
  );
}


