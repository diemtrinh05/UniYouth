using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using UniYouth.Api.Contracts.DTOs.Attendance;
using UniYouth.Api.Contracts.DTOs.Points;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Application.Services.AttendanceSupport;
using UniYouth.Api.Shared.Enums;
using UniYouth.Api.Shared.FaceVerification;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services
{
    public interface IAttendanceService
    {
        Task<CheckInResultDto> CheckInAsync(CheckInRequestDto request, int userId, string? ipAddress, string? deviceInfo, string? userAgent);
        Task<CheckInRequirementsDto> GetCheckInRequirementsAsync(string qrToken);
        Task<UniYouth.Api.Contracts.DTOs.Common.PaginatedResultDto<AttendanceHistoryDto>> GetMyHistoryAsync(int userId, int pageNumber, int pageSize);
        Task<bool> HasCheckedInAsync(int eventId, int userId);
    }

    /// <summary>
    /// Service xử lý toàn bộ nghiệp vụ liên quan đến điểm danh (attendance)
    /// 
    /// NGUYÊN TẮC THIẾT KẾ:
    /// - Toàn bộ business logic nằm ở Service
    /// - Controller chỉ có nhiệm vụ điều phối request / response
    /// - Database luôn lưu thời gian theo giờ Việt Nam (UTC+7)
    /// </summary>
    public class AttendanceService : IAttendanceService
    {
        private const string ErrorAlreadyCheckedIn = "ATTENDANCE_ALREADY_CHECKED_IN";

        private readonly UniYouthDbContext _context;
        private readonly ILogger<AttendanceService> _logger;
        private readonly IActivityPointService _activityPointService;
        private readonly INotificationService _notificationService;
        private readonly IFaceProfileSelectionService _faceProfileSelectionService;
        private readonly IFaceVerificationClient _faceVerificationClient;
        private readonly ILivenessVerificationClient _livenessVerificationClient;
        private readonly IAttendanceRiskScoringService _attendanceRiskScoringService;
        private readonly FaceVerificationOptions _faceVerificationOptions;
        private readonly AttendanceAuditService _attendanceAuditService;
        private readonly AttendanceRetryPolicyService _retryPolicyService;
        private readonly AttendanceGpsValidationService _gpsValidationService;
        private readonly AttendanceBiometricService _biometricService;
        private readonly AttendanceCheckInPrecheckService _precheckService;
        private readonly AttendanceResultMapper _resultMapper;

        public AttendanceService(
            UniYouthDbContext context,
            ILogger<AttendanceService> logger,
            IActivityPointService activityPointService,
            INotificationService notificationService,
            IFaceProfileSelectionService faceProfileSelectionService,
            IFaceVerificationClient faceVerificationClient,
            ILivenessVerificationClient livenessVerificationClient,
            IAttendanceRiskScoringService attendanceRiskScoringService,
            IOptions<FaceVerificationOptions> faceVerificationOptions)
        {
            _context = context;
            _logger = logger;
            _activityPointService = activityPointService;
            _notificationService = notificationService;
            _faceProfileSelectionService = faceProfileSelectionService;
            _faceVerificationClient = faceVerificationClient;
            _livenessVerificationClient = livenessVerificationClient;
            _attendanceRiskScoringService = attendanceRiskScoringService;
            _faceVerificationOptions = faceVerificationOptions.Value;
            _attendanceAuditService = new AttendanceAuditService(_context);
            _retryPolicyService = new AttendanceRetryPolicyService(_faceVerificationOptions);
            _gpsValidationService = new AttendanceGpsValidationService(_logger);
            _biometricService = new AttendanceBiometricService(
                _faceProfileSelectionService,
                _faceVerificationClient,
                _livenessVerificationClient,
                _logger,
                _faceVerificationOptions);
            _precheckService = new AttendanceCheckInPrecheckService(
                _context,
                _logger,
                _notificationService,
                _attendanceAuditService,
                _retryPolicyService);
            _resultMapper = new AttendanceResultMapper(_retryPolicyService);
        }

        /// <summary>
        /// Thực hiện điểm danh cho người dùng bằng QR code kết hợp GPS
        /// 
        /// QUY TRÌNH XÁC THỰC ĐIỂM DANH:
        /// 1. Kiểm tra mã QR (tồn tại, đang hoạt động)
        /// 2. Kiểm tra thời gian hiệu lực của QR
        /// 3. Kiểm tra sự kiện (đang diễn ra)
        /// 4. Kiểm tra người dùng đã đăng ký hay chưa
        /// 5. Kiểm tra trùng điểm danh
        /// 6. Kiểm tra khoảng cách GPS
        /// 7. Ghi nhận attendance (kể cả không hợp lệ)
        /// 8. Cập nhật số lượt quét QR
        /// 
        /// LƯU Ý:
        /// - Mỗi lượt điểm danh đều được lưu để phục vụ audit và chống gian lận
        /// - Kết quả hợp lệ hay không được phản ánh qua IsValid
        /// </summary>
        public async Task<CheckInResultDto> CheckInAsync(
            CheckInRequestDto request,
            int userId,
            string? ipAddress,
            string? deviceInfo,
            string? userAgent)
        {
            // Sử dụng ExecutionStrategy để đảm bảo an toàn khi có retry (SQL Server)
            var strategy = _context.Database.CreateExecutionStrategy();

            return await strategy.ExecuteAsync(async () =>
            {
                Microsoft.EntityFrameworkCore.Storage.IDbContextTransaction? transaction = null;

                try
                {
                    // Thời điểm check-in do server sinh ra (giờ Việt Nam)
                    var now = DateTime.Now;
                    var clientDeviceId = string.IsNullOrWhiteSpace(request.ClientDeviceId)
                        ? null
                        : request.ClientDeviceId.Trim();

                    if (!string.IsNullOrEmpty(clientDeviceId) && clientDeviceId.Length > 128)
                    {
                        clientDeviceId = clientDeviceId[..128];
                    }
                    var precheck = await _precheckService.PrepareAsync(
                        request,
                        userId,
                        now,
                        ipAddress,
                        userAgent);

                    var qrCode = precheck.QrCode;
                    var eventEntity = precheck.Event;
                    var existingAttendance = precheck.ExistingAttendance;
                    var isFaceRetryFlow = precheck.IsFaceRetryFlow;

                    var gpsValidation = _gpsValidationService.Validate(eventEntity, request, userId);
                    var isValid = gpsValidation.IsValid;
                    var isGpsInvalid = gpsValidation.IsGpsInvalid;
                    var invalidReason = gpsValidation.InvalidReason;
                    var distance = gpsValidation.Distance;

                    var faceResult = await _biometricService.ResolveFaceVerificationAsync(eventEntity, userId, request);
                    var livenessResult = await _biometricService.ResolveLivenessVerificationAsync(eventEntity, userId, request);

                    _logger.LogInformation(
                        "Check-in biometric telemetry: Event {EventId}, User {UserId}, FaceStatus {FaceStatus}, FaceConfidence {FaceConfidence}, FaceQuality {FaceQuality}, FaceSource {FaceSource}, LivenessStatus {LivenessStatus}, LivenessPassed {LivenessPassed}, LivenessScore {LivenessScore}",
                        eventEntity.EventID,
                        userId,
                        faceResult.FaceVerificationStatus,
                        faceResult.FaceConfidence,
                        faceResult.QualityScore,
                        faceResult.ProbeSource,
                        livenessResult.LivenessStatus,
                        livenessResult.LivenessPassed,
                        livenessResult.LivenessScore);

                    if (eventEntity.EnableFaceVerification
                        && !string.Equals(
                            faceResult.FaceVerificationStatus,
                            "Matched",
                            StringComparison.OrdinalIgnoreCase))
                    {
                        isValid = false;
                        invalidReason = _retryPolicyService.AppendInvalidReason(
                            invalidReason,
                            _retryPolicyService.BuildInvalidFaceReason(faceResult));

                        _logger.LogWarning(
                            "Điểm danh không hợp lệ (FACE): Event {EventId}, User {UserId}, FaceStatus {FaceStatus}",
                            eventEntity.EventID,
                            userId,
                            faceResult.FaceVerificationStatus);
                    }

                    AttendanceRiskScoringResult riskResult;
                    try
                    {
                        riskResult = await _attendanceRiskScoringService.ScoreAsync(new AttendanceRiskScoringContext
                        {
                            EventId = eventEntity.EventID,
                            UserId = userId,
                            CheckInTime = now,
                            IsGpsInvalid = isGpsInvalid,
                            FaceVerificationStatus = faceResult.FaceVerificationStatus,
                            LivenessStatus = livenessResult.LivenessStatus,
                            LivenessPassed = livenessResult.LivenessPassed,
                            ClientDeviceId = clientDeviceId,
                            IPAddress = ipAddress
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(
                            ex,
                            "Failed to calculate attendance risk score. Event {EventId}, User {UserId}",
                            eventEntity.EventID,
                            userId);

                        riskResult = AttendanceRiskScoringResult.DefaultLowRisk();
                    }

                    // =====================================================================
                    // STEP 8: GHI NHẬN ATTENDANCE (LUÔN LƯU)
                    // Always create record, even if invalid (for audit trail)
                    // =====================================================================
                    transaction = await _context.Database.BeginTransactionAsync();
                    var attendance = isFaceRetryFlow
                        ? existingAttendance!
                        : new Attendance
                        {
                            EventID = eventEntity.EventID,
                            UserID = userId,
                            CreatedDate = now,
                            FaceRetryCount = 0
                        };

                    attendance.QRID = qrCode.QRID;
                    attendance.CheckInMethod = "QR_GPS";
                    attendance.CheckInTime = now;
                    attendance.UserLatitude = request.Latitude;
                    attendance.UserLongitude = request.Longitude;
                    attendance.Distance = distance;
                    attendance.FaceVerified = faceResult.FaceVerified;
                    attendance.FaceConfidence = faceResult.FaceConfidence;
                    attendance.FaceVerificationStatus = faceResult.FaceVerificationStatus;
                    attendance.FaceVerificationReason = faceResult.FaceVerificationMessage;
                    attendance.FaceVerificationProvider = faceResult.Provider;
                    attendance.FaceVerificationVersion = faceResult.Version;
                    attendance.LivenessPassed = livenessResult.LivenessPassed;
                    attendance.LivenessScore = livenessResult.LivenessScore;
                    attendance.LivenessReason = livenessResult.LivenessReason;
                    attendance.RiskScore = riskResult.RiskScore;
                    attendance.RiskLevel = riskResult.RiskLevel;
                    attendance.RiskReasonsJson = riskResult.RiskReasonsJson;
                    attendance.IsValid = isValid;
                    attendance.InvalidReason = invalidReason;
                    attendance.IPAddress = ipAddress;
                    attendance.DeviceInfo = deviceInfo;
                    attendance.ClientDeviceId = clientDeviceId;

                    if (isFaceRetryFlow)
                    {
                        attendance.FaceRetryCount = attendance.FaceRetryCount.GetValueOrDefault() + 1;
                    }

                    if (faceResult.ShouldCreateFaceLog)
                    {
                        attendance.FaceRecognitionLogs.Add(new FaceRecognitionLog
                        {
                            FaceProfileID = faceResult.FaceProfileId,
                            SimilarityScore = faceResult.RawScore,
                            Threshold = faceResult.Threshold,
                            IsMatched = faceResult.IsMatchedForLog,
                            ProcessingTime = faceResult.ProcessingTimeMs,
                            VerificationStatus = Truncate(faceResult.FaceVerificationStatus, 30),
                            Provider = Truncate(faceResult.Provider, 50),
                            Model = Truncate(faceResult.Model, 50),
                            ErrorCode = Truncate(faceResult.ErrorCode, 50),
                            CapturedImageUrl = null,
                            ErrorMessage = Truncate(faceResult.ErrorMessage, 255),
                            CreatedDate = now
                        });
                    }

                    if (!isFaceRetryFlow)
                    {
                        _context.Attendances.Add(attendance);
                    }

                    // =====================================================================
                    // STEP 9: CẬP NHẬT SỐ LƯỢT QUÉT QR
                    // =====================================================================
                    qrCode.CurrentScans += 1;
                    qrCode.UpdatedDate = now;
                    _context.EventQRCodes.Update(qrCode);

                    // =====================================================================
                    // STEP 11: AWARD POINTS (NEW - Tự động cộng điểm)
                    // =====================================================================
                    PointAwardedDto? pointsAwarded = null;

                    if (isValid)
                    {
                        // Chỉ cộng điểm nếu attendance hợp lệ
                        try
                        {
                            pointsAwarded = await _activityPointService.AwardPointsForAttendanceAsync(
                                eventEntity.EventID,
                                userId,
                                attendance.AttendanceID
                            );

                            if (pointsAwarded != null)
                            {
                                _logger.LogInformation(
                                    "Points awarded automatically: User {UserId}, Event {EventId}, Points {Points}",
                                    userId, eventEntity.EventID, pointsAwarded.Points);
                            }
                        }
                        catch (Exception ex)
                        {
                            // Log error nhưng KHÔNG rollback transaction
                            // Point awarding là "nice to have", không critical
                            _logger.LogError(ex,
                                "Failed to award points but attendance saved: User {UserId}, Event {EventId}",
                                userId, eventEntity.EventID);

                            // Continue without failing the check-in
                        }
                    }

                    // =====================================================================
                    // STEP 10: LƯU DỮ LIỆU
                    // =====================================================================
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Tạo notification (không ảnh hưởng flow chính)
                    try
                    {
                        await _notificationService.CreateAttendanceNotificationAsync(
                            userId,
                            eventEntity.EventID,
                            eventEntity.EventName,
                            isValid,
                            pointsAwarded?.Points,
                            invalidReason
                        );
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex,
                            "Không tạo được notification điểm danh: User {UserId}, Event {EventId}",
                            userId, eventEntity.EventID);
                    }

                    try
                    {
                        await _notificationService.CreateSuspiciousAttendanceAlertAsync(
                            attendance.AttendanceID,
                            eventEntity.EventID,
                            eventEntity.EventName,
                            userId,
                            attendance.RiskScore,
                            attendance.RiskLevel,
                            attendance.FaceVerificationStatus);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex,
                            "Không tạo được suspicious attendance notification: Attendance {AttendanceId}, Event {EventId}, User {UserId}",
                            attendance.AttendanceID,
                            eventEntity.EventID,
                            userId);
                    }

                    if (qrCode.ScanLimit.HasValue
                        && qrCode.CurrentScans == qrCode.ScanLimit.Value)
                    {
                        try
                        {
                            await _notificationService.CreateQrScanLimitReachedAlertAsync(
                                eventEntity.EventID,
                                eventEntity.EventName,
                                qrCode.QRID,
                                qrCode.CurrentScans ?? 0,
                                qrCode.ScanLimit.Value);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex,
                                "Không thể tạo alert QR scan limit reached (commit path): Event {EventId}, QR {QrId}",
                                eventEntity.EventID, qrCode.QRID);
                        }
                    }

                    // =====================================================================
                    // STEP 11: LOG SUCCESS
                    // =====================================================================
                    _logger.LogInformation(
                        "Điểm danh hoàn tất: Event {EventId}, User {UserId}, Valid {IsValid}, " +
                        "Distance {Distance}m, Time {Time}",
                        eventEntity.EventID, userId, isValid, distance, now);

                    // =====================================================================
                    // STEP 12: TRẢ KẾT QUẢ
                    // =====================================================================
                    return _resultMapper.MapCheckInResult(
                        eventEntity,
                        attendance,
                        now,
                        isValid,
                        invalidReason,
                        distance,
                        pointsAwarded);
                }
                catch (DbUpdateException ex) when (
                    ex.InnerException?.Message.Contains("IX_Attendances") == true ||
                    ex.InnerException?.Message.Contains("UNIQUE") == true)
                {
                    // Handle race condition: Duplicate check-in attempt
                    if (transaction != null)
                    {
                        await transaction.RollbackAsync();
                    }
                    _logger.LogWarning(ex, "Điểm danh trùng lặp: User {UserId}", userId);

                    try
                    {
                        await _attendanceAuditService.WriteAsync(
                            userId,
                            action: "ATTENDANCE_CHECKIN_FAILED",
                            tableName: "Attendances",
                            recordId: null,
                            details: new { reason = "DUPLICATE_CHECKIN_DB_CONSTRAINT" },
                            ipAddress,
                            userAgent,
                            DateTime.Now);
                    }
                    catch (Exception auditEx)
                    {
                        _logger.LogError(auditEx, "Không thể ghi AuditLog cho điểm danh trùng lặp: User {UserId}", userId);
                    }

                    throw new InvalidOperationException(
                        AttendanceRetryPolicyService.BuildErrorMessage(ErrorAlreadyCheckedIn, "Bạn đã điểm danh cho sự kiện này"));
                }
                catch (Exception ex)
                {
                    if (transaction != null)
                    {
                        await transaction.RollbackAsync();
                    }
                    _logger.LogError(ex, "Lỗi khi xử lý điểm danh: User {UserId}", userId);
                    throw;
                }
            });
        }

        public async Task<CheckInRequirementsDto> GetCheckInRequirementsAsync(string qrToken)
        {
            var normalizedQrToken = qrToken?.Trim();
            if (string.IsNullOrWhiteSpace(normalizedQrToken))
            {
                throw new ArgumentException("QR token là bắt buộc", nameof(qrToken));
            }

            var qrCode = await _context.EventQRCodes
                .AsNoTracking()
                .Include(qr => qr.Event)
                .FirstOrDefaultAsync(qr => qr.QRToken == normalizedQrToken);

            if (qrCode == null || qrCode.Event == null)
            {
                throw new KeyNotFoundException(
                    AttendanceRetryPolicyService.BuildErrorMessage(AttendanceErrorCodes.QrNotFound, "Mã QR không hợp lệ hoặc không tồn tại"));
            }

            var now = DateTime.Now;
            if (qrCode.IsActive != true)
            {
                throw new InvalidOperationException(
                    AttendanceRetryPolicyService.BuildErrorMessage(AttendanceErrorCodes.QrInactive, "Mã QR hiện không còn hiệu lực"));
            }

            if (now < qrCode.ValidFrom)
            {
                throw new InvalidOperationException(
                    AttendanceRetryPolicyService.BuildErrorMessage(
                        AttendanceErrorCodes.QrNotStarted,
                        $"Mã QR chưa có hiệu lực. Có hiệu lực từ: {qrCode.ValidFrom:dd/MM/yyyy HH:mm}"));
            }

            if (now > qrCode.ValidUntil)
            {
                throw new InvalidOperationException(
                    AttendanceRetryPolicyService.BuildErrorMessage(
                        AttendanceErrorCodes.QrExpired,
                        $"Mã QR đã hết hạn. Hết hạn lúc: {qrCode.ValidUntil:dd/MM/yyyy HH:mm}"));
            }

            if (qrCode.ScanLimit.HasValue && qrCode.CurrentScans >= qrCode.ScanLimit.Value)
            {
                throw new InvalidOperationException(
                    AttendanceRetryPolicyService.BuildErrorMessage(
                        AttendanceErrorCodes.QrScanLimitReached,
                        $"Mã QR đã đạt giới hạn quét ({qrCode.ScanLimit} lần)"));
            }

            if (qrCode.Event.Status != (byte)EventStatus.Ongoing)
            {
                throw new InvalidOperationException(
                    AttendanceRetryPolicyService.BuildErrorMessage(AttendanceErrorCodes.EventNotOngoing, "Sự kiện chưa bắt đầu hoặc đã kết thúc"));
            }

            return new CheckInRequirementsDto
            {
                EventId = qrCode.EventID,
                EventName = qrCode.Event.EventName,
                EnableFaceVerification = qrCode.Event.EnableFaceVerification
            };
        }

        /// <summary>
        /// Lấy lịch sử điểm danh của người dùng hiện tại
        /// </summary>
        public async Task<UniYouth.Api.Contracts.DTOs.Common.PaginatedResultDto<AttendanceHistoryDto>> GetMyHistoryAsync(int userId, int pageNumber, int pageSize)
        {
            if (pageNumber < 1)
            {
                pageNumber = 1;
            }

            if (pageSize < 1)
            {
                pageSize = 20;
            }

            var baseQuery = _context.Attendances
                .Where(a => a.UserID == userId)
                .AsNoTracking();

            var totalCount = await baseQuery.CountAsync();

            var items = await baseQuery
                .OrderByDescending(a => a.CheckInTime)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .Select(a => new AttendanceHistoryDto
                {
                    AttendanceID = a.AttendanceID,
                    EventID = a.EventID,
                    EventName = a.Event.EventName,
                    CheckInTime = a.CheckInTime.HasValue
                                ? DateTimeHelper.ToVietnamTime(a.CheckInTime.Value)
                                : null,
                    IsValid = a.IsValid,
                    Distance = a.Distance,
                    InvalidReason = a.InvalidReason,
                    AttendancePointID = _context.ActivityPoints
                        .Where(ap => ap.EventID == a.EventID
                                     && ap.UserID == a.UserID
                                     && ap.PointType == PointTypeEnum.Attendance.ToString())
                        .Select(ap => (int?)ap.PointID)
                        .FirstOrDefault(),
                    HasAttendancePointsAwarded = _context.ActivityPoints
                        .Any(ap => ap.EventID == a.EventID
                                   && ap.UserID == a.UserID
                                   && ap.PointType == PointTypeEnum.Attendance.ToString()),
                    
                })
                .ToListAsync();

            return new UniYouth.Api.Contracts.DTOs.Common.PaginatedResultDto<AttendanceHistoryDto>
            {
                Items = items,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        /// <summary>
        /// Kiểm tra người dùng đã điểm danh cho sự kiện hay chưa
        /// </summary>
        public async Task<bool> HasCheckedInAsync(int eventId, int userId)
        {
            return await _context.Attendances
                .AnyAsync(a => a.EventID == eventId && a.UserID == userId);
        }
        private static string? Truncate(string? value, int maxLength)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return null;
            }

            var trimmed = value.Trim();
            return trimmed.Length <= maxLength ? trimmed : trimmed[..maxLength];
        }
    }
}
