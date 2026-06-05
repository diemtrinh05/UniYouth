import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/core/error/attendance_error_mapper.dart';

void main() {
  group('AttendanceErrorMapper.mapCheckInError', () {
    test('map coded QR not found', () {
      const error = AppError(
        type: AppErrorType.notFound,
        statusCode: 404,
        message:
            '[ATTENDANCE_QR_NOT_FOUND] Mã QR không tồn tại hoặc đã bị thu hồi',
      );

      final mapped = AttendanceErrorMapper.mapCheckInError(error);

      expect(mapped.type, AttendanceEdgeCaseType.qrInvalid);
      expect(mapped.title, 'QR không hợp lệ');
    });

    test('map coded QR expired', () {
      const error = AppError(
        type: AppErrorType.badRequest,
        statusCode: 400,
        message:
            '[ATTENDANCE_QR_EXPIRED] Mã QR đã hết hạn. Hết hạn lúc: 12/04/2026 08:00',
      );

      final mapped = AttendanceErrorMapper.mapCheckInError(error);

      expect(mapped.type, AttendanceEdgeCaseType.qrExpired);
    });

    test('map coded already checked in', () {
      const error = AppError(
        type: AppErrorType.badRequest,
        statusCode: 400,
        message:
            '[ATTENDANCE_ALREADY_CHECKED_IN] Bạn đã điểm danh lúc 08:00:00 12/04/2026',
      );

      final mapped = AttendanceErrorMapper.mapCheckInError(error);

      expect(mapped.type, AttendanceEdgeCaseType.alreadyCheckedIn);
      expect(mapped.message, 'Bạn đã điểm danh lúc 08:00:00 12/04/2026');
    });

    test('map coded retry exhausted', () {
      const error = AppError(
        type: AppErrorType.badRequest,
        statusCode: 400,
        message:
            '[ATTENDANCE_FACE_RETRY_LIMIT_REACHED] Bạn đã hết số lượt thử lại xác minh khuôn mặt cho sự kiện này.',
      );

      final mapped = AttendanceErrorMapper.mapCheckInError(error);

      expect(mapped.type, AttendanceEdgeCaseType.retryExhausted);
      expect(mapped.title, 'Đã hết lượt thử lại');
    });

    test('fallback keyword mapping for event status invalid', () {
      const error = AppError(
        type: AppErrorType.badRequest,
        statusCode: 400,
        message: 'Sự kiện chưa diễn ra.',
      );

      final mapped = AttendanceErrorMapper.mapCheckInError(error);

      expect(mapped.type, AttendanceEdgeCaseType.eventNotOngoing);
    });
  });

  group('AttendanceErrorMapper.mapInvalidCheckInResult', () {
    test('map invalid GPS result by coded reason', () {
      final mapped = AttendanceErrorMapper.mapInvalidCheckInResult(
        isValid: false,
        invalidReason:
            '[ATTENDANCE_GPS_OUT_OF_RANGE] Vị trí quá xa (120m). Phạm vi cho phép: 100m',
        distance: 120.5,
      );

      expect(mapped, isNotNull);
      expect(mapped!.type, AttendanceEdgeCaseType.distanceTooFar);
      expect(mapped.message.contains('120.50 m'), isTrue);
    });

    test('map invalid face mismatch result', () {
      final mapped = AttendanceErrorMapper.mapInvalidCheckInResult(
        isValid: false,
        invalidReason:
            '[ATTENDANCE_FACE_MISMATCH] Khuôn mặt không khớp hồ sơ đã đăng ký.',
        distance: 8,
        faceVerificationStatus: 'Mismatch',
      );

      expect(mapped, isNotNull);
      expect(mapped!.type, AttendanceEdgeCaseType.faceMismatch);
      expect(mapped.title, 'Khuôn mặt không khớp');
    });

    test('map invalid face technical result from status fallback', () {
      final mapped = AttendanceErrorMapper.mapInvalidCheckInResult(
        isValid: false,
        invalidReason: 'Xác minh khuôn mặt không đạt yêu cầu.',
        distance: null,
        faceVerificationStatus: 'TechnicalError',
      );

      expect(mapped, isNotNull);
      expect(mapped!.type, AttendanceEdgeCaseType.faceTechnicalError);
    });
  });
}
