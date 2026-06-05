class CheckInResult {
  const CheckInResult({
    required this.isValid,
    required this.invalidReason,
    required this.distance,
    required this.pointsAwarded,
    required this.isSuccess,
    required this.message,
    required this.eventName,
    required this.checkInTime,
    required this.attendanceId,
    required this.faceVerified,
    required this.faceConfidence,
    required this.faceVerificationStatus,
    required this.faceVerificationMessage,
    required this.riskScore,
    required this.riskLevel,
  });

  final bool isValid;
  final String? invalidReason;
  final double? distance;
  final CheckInPointsAwarded? pointsAwarded;
  final bool isSuccess;
  final String? message;
  final String? eventName;
  final DateTime? checkInTime;
  final int? attendanceId;
  final bool? faceVerified;
  final double? faceConfidence;
  final String? faceVerificationStatus;
  final String? faceVerificationMessage;
  final int? riskScore;
  final String? riskLevel;
}

class CheckInPointsAwarded {
  const CheckInPointsAwarded({
    required this.points,
    required this.pointType,
    required this.roleType,
    required this.currentTotalPoints,
  });

  final int? points;
  final String? pointType;
  final String? roleType;
  final int? currentTotalPoints;
}

class CheckInLivenessPayload {
  const CheckInLivenessPayload({
    required this.mode,
    required this.frameCount,
    required this.mimeType,
    required this.frames,
  });

  final String mode;
  final int frameCount;
  final String mimeType;
  final List<CheckInLivenessFrame> frames;
}

class CheckInLivenessFrame {
  const CheckInLivenessFrame({
    required this.frameIndex,
    required this.imageBase64,
    required this.capturedAtMs,
  });

  final int frameIndex;
  final String imageBase64;
  final int capturedAtMs;
}

abstract class CheckInRepository {
  Future<CheckInResult> checkIn({
    required String qrToken,
    required double latitude,
    required double longitude,
    String? deviceInfo,
    String? clientDeviceId,
    String? faceImageBase64,
    String? faceImageMimeType,
    CheckInLivenessPayload? liveness,
  });
}

class CheckInUseCase {
  const CheckInUseCase({required CheckInRepository repository})
    : _repository = repository;

  final CheckInRepository _repository;

  // Submit attendance check-in using qrToken and coordinates captured at scan time.
  Future<CheckInResult> call({
    required String qrToken,
    required double latitude,
    required double longitude,
    String? deviceInfo,
    String? clientDeviceId,
    String? faceImageBase64,
    String? faceImageMimeType,
    CheckInLivenessPayload? liveness,
  }) {
    return _repository.checkIn(
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
