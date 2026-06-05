import 'app_error.dart';
import '../../presentation/shared/formatters/distance_formatter.dart';

enum AttendanceEdgeCaseType {
  qrInvalid,
  qrExpired,
  qrNotYetValid,
  qrInactive,
  qrScanLimitExceeded,
  notRegistered,
  registrationCancelled,
  alreadyCheckedIn,
  retryExhausted,
  eventNotOngoing,
  distanceTooFar,
  faceMismatch,
  faceReview,
  noFaceDetected,
  multipleFacesDetected,
  blurryFaceImage,
  faceInvalidPayload,
  faceProfileMissing,
  faceTechnicalError,
  unknown,
}

class AttendanceEdgeCaseUi {
  const AttendanceEdgeCaseUi({
    required this.type,
    required this.title,
    required this.message,
  });

  final AttendanceEdgeCaseType type;
  final String title;
  final String message;
}

class AttendanceErrorMapper {
  const AttendanceErrorMapper._();

  static AttendanceEdgeCaseUi mapCheckInError(AppError error) {
    final codedSource = _joinMessageParts(error.message, error.detail);
    final errorCode = _extractErrorCode(codedSource);

    final mappedByCode = _mapByErrorCode(
      errorCode,
      distance: null,
      faceVerificationStatus: null,
      fallbackMessage: _stripErrorCodes(error.message),
    );
    if (mappedByCode != null) {
      return mappedByCode;
    }

    if (error.statusCode == 429) {
      return const AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.unknown,
        title: 'Thao tác quá nhanh',
        message: 'Bạn thao tác quá nhanh. Vui lòng đợi một lúc rồi thử lại.',
      );
    }

    final fieldError = _firstFieldError(error);
    if (fieldError != null) {
      return AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.unknown,
        title: 'Dữ liệu không hợp lệ',
        message: fieldError,
      );
    }

    if (error.statusCode == 403) {
      return AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.unknown,
        title: 'Không có quyền truy cập',
        message: _stripErrorCodes(error.message),
      );
    }

    if (error.statusCode == 404) {
      return AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.qrInvalid,
        title: 'QR không hợp lệ',
        message: _stripErrorCodes(error.message),
      );
    }

    if (error.statusCode != 400) {
      return AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.unknown,
        title: 'Lỗi điểm danh',
        message: _stripErrorCodes(error.message),
      );
    }

    final message = _normalize(error.message);
    final detail = _normalize(error.detail);
    final source = '$message $detail';

    if (_containsAny(source, const <String>['hết hạn', 'expired'])) {
      return const AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.qrExpired,
        title: 'QR hết hạn',
        message: 'Mã QR đã hết hạn. Vui lòng quét mã mới.',
      );
    }

    if (_containsAny(source, const <String>[
      'chưa tới giờ',
      'chưa hiệu lực',
      'not yet valid',
      'validfrom',
    ])) {
      return const AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.qrNotYetValid,
        title: 'QR chưa hiệu lực',
        message: 'Mã QR chưa tới thời điểm sử dụng. Vui lòng thử lại sau.',
      );
    }

    if (_containsAny(source, const <String>[
      'inactive',
      'vô hiệu',
      'không hoạt động',
    ])) {
      return const AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.qrInactive,
        title: 'QR không hoạt động',
        message: 'Mã QR đã bị vô hiệu hóa hoặc không còn hoạt động.',
      );
    }

    if (_containsAny(source, const <String>[
      'scan limit',
      'giới hạn quét',
      'vượt quá số lượt',
    ])) {
      return const AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.qrScanLimitExceeded,
        title: 'Vượt giới hạn quét',
        message: 'Mã QR đã vượt giới hạn lượt quét.',
      );
    }

    if (_containsAny(source, const <String>['chưa đăng ký'])) {
      return const AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.notRegistered,
        title: 'Chưa đăng ký sự kiện',
        message: 'Bạn chưa đăng ký sự kiện này nên không thể điểm danh.',
      );
    }

    if (_containsAny(source, const <String>[
      'đã điểm danh',
      'already checked in',
      'already check in',
    ])) {
      return const AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.alreadyCheckedIn,
        title: 'Đã điểm danh',
        message: 'Bạn đã điểm danh sự kiện này trước đó.',
      );
    }

    if (_containsAny(source, const <String>[
      'chưa diễn ra',
      'không còn diễn ra',
      'not ongoing',
      'ongoing',
      'đã kết thúc',
    ])) {
      return const AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.eventNotOngoing,
        title: 'Sự kiện chưa thể điểm danh',
        message: 'Sự kiện chưa diễn ra hoặc đã kết thúc.',
      );
    }

    return AttendanceEdgeCaseUi(
      type: AttendanceEdgeCaseType.unknown,
      title: 'Lỗi điểm danh',
      message: _stripErrorCodes(error.message),
    );
  }

  static AttendanceEdgeCaseUi? mapInvalidCheckInResult({
    required bool isValid,
    required String? invalidReason,
    required double? distance,
    String? faceVerificationStatus,
  }) {
    if (isValid) {
      return null;
    }

    final source = _joinMessageParts(invalidReason, null);
    final errorCode = _extractErrorCode(source);

    final mappedByCode = _mapByErrorCode(
      errorCode,
      distance: distance,
      faceVerificationStatus: faceVerificationStatus,
      fallbackMessage: _stripErrorCodes(invalidReason),
    );
    if (mappedByCode != null) {
      return mappedByCode;
    }

    if (distance != null && distance.isFinite && distance > 0) {
      return AttendanceEdgeCaseUi(
        type: AttendanceEdgeCaseType.distanceTooFar,
        title: 'Vị trí quá xa',
        message:
            'Bạn đang ở ngoài phạm vi điểm danh. Khoảng cách hiện tại: ${_formatDistance(distance)}.',
      );
    }

    return AttendanceEdgeCaseUi(
      type: AttendanceEdgeCaseType.unknown,
      title: 'Điểm danh không hợp lệ',
      message: (invalidReason ?? '').trim().isEmpty
          ? 'Kết quả điểm danh chưa hợp lệ theo quy tắc hiện tại của hệ thống.'
          : _stripErrorCodes(invalidReason),
    );
  }

  static String _formatDistance(double? distance) =>
      DistanceFormatter.formatMeters(distance);

  static String _normalize(Object? value) {
    return (value?.toString() ?? '').trim().toLowerCase();
  }

  static String _joinMessageParts(String? primary, String? secondary) {
    final parts = <String>[
      if ((primary ?? '').trim().isNotEmpty) primary!.trim(),
      if ((secondary ?? '').trim().isNotEmpty) secondary!.trim(),
    ];
    return parts.join(' ');
  }

  static String? _extractErrorCode(String source) {
    final match = RegExp(r'\[(ATTENDANCE_[A-Z_]+)\]').firstMatch(source);
    return match?.group(1);
  }

  static String _stripErrorCodes(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return value;
    }
    return value.replaceAll(RegExp(r'\[(ATTENDANCE_[A-Z_]+)\]\s*'), '').trim();
  }

  static AttendanceEdgeCaseUi? _mapByErrorCode(
    String? errorCode, {
    required double? distance,
    required String? faceVerificationStatus,
    required String? fallbackMessage,
  }) {
    switch (errorCode) {
      case 'ATTENDANCE_QR_NOT_FOUND':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.qrInvalid,
          title: 'QR không hợp lệ',
          message: 'Mã QR không tồn tại, đã bị thu hồi hoặc không còn dùng được.',
        );
      case 'ATTENDANCE_QR_INACTIVE':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.qrInactive,
          title: 'QR không hoạt động',
          message: 'Mã QR đã bị vô hiệu hóa hoặc không còn hoạt động.',
        );
      case 'ATTENDANCE_QR_NOT_STARTED':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.qrNotYetValid,
          title: 'QR chưa hiệu lực',
          message: 'Mã QR chưa tới thời điểm sử dụng. Vui lòng thử lại sau.',
        );
      case 'ATTENDANCE_QR_EXPIRED':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.qrExpired,
          title: 'QR hết hạn',
          message: 'Mã QR đã hết hạn. Vui lòng quét mã mới.',
        );
      case 'ATTENDANCE_QR_SCAN_LIMIT_REACHED':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.qrScanLimitExceeded,
          title: 'Vượt giới hạn quét',
          message: 'Mã QR đã vượt giới hạn lượt quét.',
        );
      case 'ATTENDANCE_EVENT_NOT_ONGOING':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.eventNotOngoing,
          title: 'Sự kiện chưa thể điểm danh',
          message: 'Sự kiện chưa diễn ra hoặc đã kết thúc.',
        );
      case 'ATTENDANCE_NOT_REGISTERED':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.notRegistered,
          title: 'Chưa đăng ký sự kiện',
          message: 'Bạn chưa đăng ký sự kiện này nên không thể điểm danh.',
        );
      case 'ATTENDANCE_REGISTRATION_CANCELLED':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.registrationCancelled,
          title: 'Đăng ký đã bị hủy',
          message: 'Đăng ký tham gia sự kiện của bạn đã bị hủy.',
        );
      case 'ATTENDANCE_ALREADY_CHECKED_IN':
        return AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.alreadyCheckedIn,
          title: 'Đã điểm danh',
          message: fallbackMessage ?? 'Bạn đã điểm danh sự kiện này trước đó.',
        );
      case 'ATTENDANCE_FACE_RETRY_LIMIT_REACHED':
        return AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.retryExhausted,
          title: 'Đã hết lượt thử lại',
          message:
              fallbackMessage ??
              'Bạn đã hết số lượt thử lại xác minh khuôn mặt cho sự kiện này.',
        );
      case 'ATTENDANCE_GPS_OUT_OF_RANGE':
        return AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.distanceTooFar,
          title: 'Vị trí quá xa',
          message: distance != null && distance.isFinite && distance > 0
              ? 'Bạn đang ở ngoài phạm vi điểm danh. Khoảng cách hiện tại: ${_formatDistance(distance)}.'
              : (fallbackMessage ?? 'Bạn đang ở ngoài phạm vi điểm danh cho phép.'),
        );
      case 'ATTENDANCE_FACE_MISMATCH':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceMismatch,
          title: 'Khuôn mặt không khớp',
          message: 'Khuôn mặt chưa khớp với hồ sơ đã đăng ký.',
        );
      case 'ATTENDANCE_FACE_REVIEW':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceReview,
          title: 'Khuôn mặt chưa đủ rõ',
          message: 'Hệ thống chưa đủ cơ sở để xác nhận khuôn mặt ở lần chụp này.',
        );
      case 'ATTENDANCE_FACE_NO_FACE':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.noFaceDetected,
          title: 'Không thấy khuôn mặt',
          message: 'Ảnh gửi lên chưa nhận diện được khuôn mặt hợp lệ.',
        );
      case 'ATTENDANCE_FACE_MULTIPLE_FACES':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.multipleFacesDetected,
          title: 'Có nhiều khuôn mặt',
          message: 'Ảnh gửi lên chứa nhiều khuôn mặt, vui lòng chụp lại.',
        );
      case 'ATTENDANCE_FACE_BLURRY':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.blurryFaceImage,
          title: 'Ảnh khuôn mặt bị mờ',
          message: 'Ảnh khuôn mặt bị mờ, vui lòng chụp lại rõ hơn.',
        );
      case 'ATTENDANCE_FACE_INVALID_PAYLOAD':
      case 'ATTENDANCE_FACE_PAYLOAD_MISSING':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceInvalidPayload,
          title: 'Ảnh khuôn mặt không hợp lệ',
          message: 'Ứng dụng chưa gửi được ảnh khuôn mặt hợp lệ cho lượt điểm danh này.',
        );
      case 'ATTENDANCE_FACE_PROFILE_MISSING':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceProfileMissing,
          title: 'Chưa có hồ sơ khuôn mặt',
          message: 'Tài khoản của bạn chưa có hồ sơ khuôn mặt để đối chiếu.',
        );
      case 'ATTENDANCE_FACE_TECHNICAL_ERROR':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceTechnicalError,
          title: 'Lỗi xác minh khuôn mặt',
          message: 'Dịch vụ xác minh khuôn mặt đang tạm thời không khả dụng.',
        );
    }

    switch ((faceVerificationStatus ?? '').trim()) {
      case 'Mismatch':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceMismatch,
          title: 'Khuôn mặt không khớp',
          message: 'Khuôn mặt chưa khớp với hồ sơ đã đăng ký.',
        );
      case 'Review':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceReview,
          title: 'Khuôn mặt chưa đủ rõ',
          message: 'Hệ thống chưa đủ cơ sở để xác nhận khuôn mặt ở lần chụp này.',
        );
      case 'NoFaceDetected':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.noFaceDetected,
          title: 'Không thấy khuôn mặt',
          message: 'Ảnh gửi lên chưa nhận diện được khuôn mặt hợp lệ.',
        );
      case 'MultipleFacesDetected':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.multipleFacesDetected,
          title: 'Có nhiều khuôn mặt',
          message: 'Ảnh gửi lên chứa nhiều khuôn mặt, vui lòng chụp lại.',
        );
      case 'BlurryImage':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.blurryFaceImage,
          title: 'Ảnh khuôn mặt bị mờ',
          message: 'Ảnh khuôn mặt bị mờ, vui lòng chụp lại rõ hơn.',
        );
      case 'InvalidPayload':
      case 'PayloadMissing':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceInvalidPayload,
          title: 'Ảnh khuôn mặt không hợp lệ',
          message: 'Ứng dụng chưa gửi được ảnh khuôn mặt hợp lệ cho lượt điểm danh này.',
        );
      case 'ProfileMissing':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceProfileMissing,
          title: 'Chưa có hồ sơ khuôn mặt',
          message: 'Tài khoản của bạn chưa có hồ sơ khuôn mặt để đối chiếu.',
        );
      case 'TechnicalError':
        return const AttendanceEdgeCaseUi(
          type: AttendanceEdgeCaseType.faceTechnicalError,
          title: 'Lỗi xác minh khuôn mặt',
          message: 'Dịch vụ xác minh khuôn mặt đang tạm thời không khả dụng.',
        );
    }

    return null;
  }

  static bool _containsAny(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  static String? _firstFieldError(AppError error) {
    final fieldErrors = error.fieldErrors;
    if (fieldErrors == null || fieldErrors.isEmpty) {
      return null;
    }

    for (final entry in fieldErrors.entries) {
      if (entry.value.isNotEmpty) {
        final message = entry.value.first.trim();
        if (message.isNotEmpty) {
          return message;
        }
      }
    }

    return null;
  }
}
