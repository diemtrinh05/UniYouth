using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Attendance;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Services.AttendanceSupport;

public sealed class AttendanceCheckInPrecheckService
{
    private readonly UniYouthDbContext _context;
    private readonly ILogger _logger;
    private readonly INotificationService _notificationService;
    private readonly AttendanceAuditService _auditService;
    private readonly AttendanceRetryPolicyService _retryPolicyService;

    public AttendanceCheckInPrecheckService(
        UniYouthDbContext context,
        ILogger logger,
        INotificationService notificationService,
        AttendanceAuditService auditService,
        AttendanceRetryPolicyService retryPolicyService)
    {
        _context = context;
        _logger = logger;
        _notificationService = notificationService;
        _auditService = auditService;
        _retryPolicyService = retryPolicyService;
    }

    public async Task<AttendanceCheckInPrecheckResult> PrepareAsync(
        CheckInRequestDto request,
        int userId,
        DateTime now,
        string? ipAddress,
        string? userAgent)
    {
        var qrCode = await _context.EventQRCodes
            .Include(qr => qr.Event)
            .Where(qr => qr.QRToken == request.QRToken)
            .FirstOrDefaultAsync();

        if (qrCode == null)
        {
            _logger.LogWarning("Điểm danh thất bại: Không tìm thấy mã QR. User {UserId}, Token: {Token}", userId, request.QRToken);
            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "EventQRCodes",
                null,
                new
                {
                    reason = "QR_NOT_FOUND",
                    qrTokenPreview = MaskToken(request.QRToken),
                    latitude = request.Latitude,
                    longitude = request.Longitude
                },
                ipAddress,
                userAgent,
                now);

            throw new KeyNotFoundException(
                AttendanceRetryPolicyService.BuildErrorMessage(AttendanceErrorCodes.QrNotFound, "Mã QR không tồn tại hoặc đã bị thu hồi"));
        }

        if (qrCode.IsActive != true)
        {
            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "EventQRCodes",
                qrCode.QRID,
                new { reason = "QR_INACTIVE", eventId = qrCode.EventID, qrId = qrCode.QRID },
                ipAddress,
                userAgent,
                now);

            throw new InvalidOperationException(
                AttendanceRetryPolicyService.BuildErrorMessage(AttendanceErrorCodes.QrInactive, "Mã QR hiện không còn hiệu lực"));
        }

        if (now < qrCode.ValidFrom)
        {
            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "EventQRCodes",
                qrCode.QRID,
                new { reason = "QR_NOT_STARTED", eventId = qrCode.EventID, qrId = qrCode.QRID, validFromUtc = qrCode.ValidFrom, nowUtc = now },
                ipAddress,
                userAgent,
                now);

            throw new InvalidOperationException(
                AttendanceRetryPolicyService.BuildErrorMessage(
                    AttendanceErrorCodes.QrNotStarted,
                    $"Mã QR chưa có hiệu lực. Có hiệu lực từ: {qrCode.ValidFrom:dd/MM/yyyy HH:mm}"));
        }

        if (now > qrCode.ValidUntil)
        {
            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "EventQRCodes",
                qrCode.QRID,
                new { reason = "QR_EXPIRED", eventId = qrCode.EventID, qrId = qrCode.QRID, validUntilUtc = qrCode.ValidUntil, nowUtc = now },
                ipAddress,
                userAgent,
                now);

            throw new InvalidOperationException(
                AttendanceRetryPolicyService.BuildErrorMessage(
                    AttendanceErrorCodes.QrExpired,
                    $"Mã QR đã hết hạn. Hết hạn lúc: {qrCode.ValidUntil:dd/MM/yyyy HH:mm}"));
        }

        if (qrCode.ScanLimit.HasValue && qrCode.CurrentScans >= qrCode.ScanLimit.Value)
        {
            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "EventQRCodes",
                qrCode.QRID,
                new
                {
                    reason = "QR_SCAN_LIMIT_REACHED",
                    eventId = qrCode.EventID,
                    qrId = qrCode.QRID,
                    scanLimit = qrCode.ScanLimit,
                    currentScans = qrCode.CurrentScans
                },
                ipAddress,
                userAgent,
                now);

            try
            {
                await _notificationService.CreateQrScanLimitReachedAlertAsync(
                    qrCode.EventID,
                    qrCode.Event?.EventName ?? $"Sự kiện {qrCode.EventID}",
                    qrCode.QRID,
                    qrCode.CurrentScans ?? 0,
                    qrCode.ScanLimit.Value);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không thể tạo alert QR scan limit reached (reject path): Event {EventId}, QR {QrId}", qrCode.EventID, qrCode.QRID);
            }

            throw new InvalidOperationException(
                AttendanceRetryPolicyService.BuildErrorMessage(
                    AttendanceErrorCodes.QrScanLimitReached,
                    $"Mã QR đã đạt giới hạn quét ({qrCode.ScanLimit} lần)"));
        }

        var eventEntity = qrCode.Event;
        if (eventEntity == null)
        {
            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "Events",
                qrCode.EventID,
                new { reason = "EVENT_NOT_FOUND", eventId = qrCode.EventID, qrId = qrCode.QRID },
                ipAddress,
                userAgent,
                now);

            throw new KeyNotFoundException(
                AttendanceRetryPolicyService.BuildErrorMessage(AttendanceErrorCodes.EventNotFound, "Không tìm thấy sự kiện"));
        }

        if (eventEntity.Status != (byte)EventStatus.Ongoing)
        {
            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "Events",
                eventEntity.EventID,
                new { reason = "EVENT_NOT_ONGOING", eventId = eventEntity.EventID, currentStatus = eventEntity.Status, qrId = qrCode.QRID },
                ipAddress,
                userAgent,
                now);

            throw new InvalidOperationException(
                AttendanceRetryPolicyService.BuildErrorMessage(AttendanceErrorCodes.EventNotOngoing, "Sự kiện chưa bắt đầu hoặc đã kết thúc"));
        }

        var registration = await _context.EventRegistrations
            .Where(er => er.EventID == eventEntity.EventID && er.UserID == userId)
            .FirstOrDefaultAsync();

        if (registration == null)
        {
            _logger.LogWarning("Điểm danh thất bại: Người dùng chưa đăng ký. Event {EventId}, User {UserId}", eventEntity.EventID, userId);

            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "EventRegistrations",
                eventEntity.EventID,
                new { reason = "USER_NOT_REGISTERED", eventId = eventEntity.EventID, qrId = qrCode.QRID },
                ipAddress,
                userAgent,
                now);

            throw new InvalidOperationException(
                AttendanceRetryPolicyService.BuildErrorMessage(AttendanceErrorCodes.NotRegistered, "Bạn chưa đăng ký tham gia sự kiện này"));
        }

        if (registration.Status != (byte)RegistrationStatus.Registered)
        {
            await _auditService.WriteAsync(
                userId,
                "ATTENDANCE_CHECKIN_FAILED",
                "EventRegistrations",
                registration.RegistrationID,
                new { reason = "REGISTRATION_CANCELLED", eventId = eventEntity.EventID, registrationId = registration.RegistrationID, qrId = qrCode.QRID },
                ipAddress,
                userAgent,
                now);

            throw new InvalidOperationException(
                AttendanceRetryPolicyService.BuildErrorMessage(
                    AttendanceErrorCodes.RegistrationCancelled,
                    "Đăng ký tham gia sự kiện của bạn đã bị hủy"));
        }

        var existingAttendance = await _context.Attendances
            .Include(a => a.FaceRecognitionLogs)
            .Where(a => a.EventID == eventEntity.EventID && a.UserID == userId)
            .FirstOrDefaultAsync();

        var isFaceRetryFlow = false;
        if (existingAttendance != null)
        {
            if (_retryPolicyService.CanRetryFaceCheckIn(existingAttendance, eventEntity))
            {
                var nextRetryCount = existingAttendance.FaceRetryCount.GetValueOrDefault() + 1;
                var remainingFaceRetryAttempts = _retryPolicyService.GetRemainingFaceRetryAttempts(nextRetryCount);

                await _auditService.WriteAsync(
                    userId,
                    "ATTENDANCE_FACE_RETRY_ALLOWED",
                    "Attendances",
                    existingAttendance.AttendanceID,
                    new
                    {
                        reason = "FACE_RETRY_ALLOWED",
                        eventId = eventEntity.EventID,
                        attendanceId = existingAttendance.AttendanceID,
                        retryCount = nextRetryCount,
                        remainingFaceRetryAttempts
                    },
                    ipAddress,
                    userAgent,
                    now);

                isFaceRetryFlow = true;
            }
            else
            {
                var duplicateReason = _retryPolicyService.ResolveDuplicateCheckInReason(existingAttendance, eventEntity);
                await _auditService.WriteAsync(
                    userId,
                    "ATTENDANCE_CHECKIN_FAILED",
                    "Attendances",
                    existingAttendance.AttendanceID,
                    new
                    {
                        reason = duplicateReason,
                        eventId = eventEntity.EventID,
                        existingAttendanceId = existingAttendance.AttendanceID,
                        existingCheckInTimeUtc = existingAttendance.CheckInTime,
                        faceRetryCount = existingAttendance.FaceRetryCount
                    },
                    ipAddress,
                    userAgent,
                    now);

                throw new InvalidOperationException(_retryPolicyService.BuildDuplicateCheckInMessage(existingAttendance, eventEntity));
            }
        }

        return new AttendanceCheckInPrecheckResult(qrCode, eventEntity, registration, existingAttendance, isFaceRetryFlow);
    }

    private static string MaskToken(string token)
    {
        if (string.IsNullOrEmpty(token))
        {
            return string.Empty;
        }

        return token.Length <= 10 ? token[..] : token[..10] + "...";
    }
}

public sealed record AttendanceCheckInPrecheckResult(
    EventQRCode QrCode,
    Event Event,
    EventRegistration Registration,
    UniYouth.Api.Domain.Entities.Attendance? ExistingAttendance,
    bool IsFaceRetryFlow);
