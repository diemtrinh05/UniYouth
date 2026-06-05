using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Reports;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;
using UniYouth.Api.Shared.Helpers;
using System.Text.Json;

namespace UniYouth.Api.Application.Services
{
    internal sealed class AttendanceRiskReasonDto
    {
        public string? Code { get; set; }
        public int Score { get; set; }
        public string? Description { get; set; }
    }

    public interface IReportingService
    {
        Task<EventAttendanceStatsDto> GetEventAttendanceStatsAsync(int eventId, int? unitId = null, int? instituteId = null);
        Task<EventAttendancesListResponseDto> GetEventAttendancesAsync(int eventId, GetEventAttendancesQueryDto query, int? unitId = null, int? instituteId = null);
        Task<AllEventsAttendanceStatsResponseDto> GetAllEventsAttendanceStatsAsync(GetAllEventsAttendanceStatsQueryDto query, int? unitId = null, int? instituteId = null);
        Task<NotificationObservabilityResponseDto> GetNotificationObservabilityAsync(GetNotificationObservabilityQueryDto query);
        Task<BiometricTelemetryListResponseDto> GetBiometricTelemetryAsync(GetBiometricTelemetryQueryDto query);
    }
    /// <summary>
    /// Service xử lý các nghiệp vụ báo cáo và thống kê
    /// 
    /// PHẠM VI:
    /// - Thống kê điểm danh theo từng sự kiện
    /// - Lấy danh sách chi tiết người đã điểm danh
    /// - Tổng hợp thống kê nhiều sự kiện cho dashboard admin
    /// 
    /// NGUYÊN TẮC THIẾT KẾ:
    /// - Chỉ ĐỌC dữ liệu (read-only)
    /// - Không thay đổi trạng thái hệ thống
    /// - Ưu tiên sử dụng database view để đảm bảo hiệu năng
    /// </summary>
    public class ReportingService : IReportingService
    {
        private readonly UniYouthDbContext _context;
        private readonly ILogger<ReportingService> _logger;

        public ReportingService(
            UniYouthDbContext context,
            ILogger<ReportingService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<BiometricTelemetryListResponseDto> GetBiometricTelemetryAsync(GetBiometricTelemetryQueryDto query)
        {
            var pageNumber = query.PageNumber <= 0 ? 1 : query.PageNumber;
            var pageSize = query.PageSize <= 0 ? 20 : Math.Min(query.PageSize, 1000);

            var baseQuery = _context.Attendances
                .AsNoTracking()
                .Where(a => a.CheckInTime != null);

            if (query.EventId.HasValue)
            {
                baseQuery = baseQuery.Where(a => a.EventID == query.EventId.Value);
            }

            if (query.From.HasValue)
            {
                baseQuery = baseQuery.Where(a => a.CheckInTime >= query.From.Value);
            }

            if (query.To.HasValue)
            {
                baseQuery = baseQuery.Where(a => a.CheckInTime <= query.To.Value);
            }

            if (query.OnlyInvalid == true)
            {
                baseQuery = baseQuery.Where(a => a.IsValid == false);
            }

            if (!string.IsNullOrWhiteSpace(query.FaceStatus))
            {
                var normalizedFaceStatus = query.FaceStatus.Trim();
                baseQuery = baseQuery.Where(a => a.FaceVerificationStatus == normalizedFaceStatus);
            }

            if (!string.IsNullOrWhiteSpace(query.LivenessStatus))
            {
                var normalizedLivenessStatus = query.LivenessStatus.Trim().ToLowerInvariant();
                baseQuery = normalizedLivenessStatus switch
                {
                    "passed" => baseQuery.Where(a => a.LivenessPassed == true),
                    "failed" => baseQuery.Where(a => a.LivenessPassed == false),
                    "review" => baseQuery.Where(a => a.LivenessPassed == null && a.LivenessReason != null && a.LivenessReason != string.Empty),
                    "na" => baseQuery.Where(a => a.LivenessPassed == null && (a.LivenessReason == null || a.LivenessReason == string.Empty)),
                    _ => baseQuery
                };
            }

            if (!string.IsNullOrWhiteSpace(query.Q))
            {
                var keyword = query.Q.Trim();
                baseQuery = baseQuery.Where(a =>
                    (a.Event != null && a.Event.EventName != null && a.Event.EventName.Contains(keyword)) ||
                    (a.User != null && a.User.FullName != null && a.User.FullName.Contains(keyword)) ||
                    (a.User != null && a.User.Code != null && a.User.Code.StartsWith(keyword)));
            }

            var totalCount = await baseQuery.CountAsync();

            var items = await baseQuery
                .OrderByDescending(a => a.CheckInTime)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .Select(a => new BiometricTelemetryItemDto
                {
                    AttendanceID = a.AttendanceID,
                    EventID = a.EventID,
                    EventName = a.Event != null ? (a.Event.EventName ?? string.Empty) : string.Empty,
                    UserID = a.UserID,
                    FullName = a.User != null ? (a.User.FullName ?? string.Empty) : string.Empty,
                    Code = a.User != null ? (a.User.Code ?? string.Empty) : string.Empty,
                    CheckInTime = a.CheckInTime,
                    IsValid = a.IsValid,
                    InvalidReason = a.InvalidReason,
                    FaceVerificationStatus = a.FaceVerificationStatus,
                    FaceConfidence = a.FaceConfidence,
                    FaceVerificationReason = a.FaceVerificationReason,
                    LivenessPassed = a.LivenessPassed,
                    LivenessScore = a.LivenessScore,
                    LivenessReason = a.LivenessReason,
                    RiskScore = a.RiskScore,
                    RiskLevel = a.RiskLevel,
                    SimilarityScore = a.FaceRecognitionLogs
                        .OrderByDescending(log => log.CreatedDate)
                        .Select(log => log.SimilarityScore)
                        .FirstOrDefault(),
                    Threshold = a.FaceRecognitionLogs
                        .OrderByDescending(log => log.CreatedDate)
                        .Select(log => log.Threshold)
                        .FirstOrDefault(),
                    FaceLogStatus = a.FaceRecognitionLogs
                        .OrderByDescending(log => log.CreatedDate)
                        .Select(log => log.VerificationStatus)
                        .FirstOrDefault(),
                    FaceProvider = a.FaceRecognitionLogs
                        .OrderByDescending(log => log.CreatedDate)
                        .Select(log => log.Provider)
                        .FirstOrDefault(),
                    FaceModel = a.FaceRecognitionLogs
                        .OrderByDescending(log => log.CreatedDate)
                        .Select(log => log.Model)
                        .FirstOrDefault(),
                    FaceProcessingTimeMs = a.FaceRecognitionLogs
                        .OrderByDescending(log => log.CreatedDate)
                        .Select(log => log.ProcessingTime)
                        .FirstOrDefault(),
                    FaceErrorCode = a.FaceRecognitionLogs
                        .OrderByDescending(log => log.CreatedDate)
                        .Select(log => log.ErrorCode)
                        .FirstOrDefault(),
                    FaceErrorMessage = a.FaceRecognitionLogs
                        .OrderByDescending(log => log.CreatedDate)
                        .Select(log => log.ErrorMessage)
                        .FirstOrDefault()
                })
                .ToListAsync();

            return new BiometricTelemetryListResponseDto
            {
                Telemetry = new PaginatedResultDto<BiometricTelemetryItemDto>
                {
                    Items = items,
                    TotalCount = totalCount,
                    PageNumber = pageNumber,
                    PageSize = pageSize
                }
            };
        }

        public async Task<NotificationObservabilityResponseDto> GetNotificationObservabilityAsync(GetNotificationObservabilityQueryDto query)
        {
            var now = DateTime.Now;
            var from = query.From ?? now.AddHours(-24);
            var to = query.To ?? now;
            if (from > to)
            {
                throw new InvalidOperationException("Khoảng thời gian không hợp lệ: From phải nhỏ hơn hoặc bằng To.");
            }

            byte? channelFilter = query.Channel;
            if (channelFilter.HasValue && !Enum.IsDefined(typeof(NotificationChannel), channelFilter.Value))
            {
                throw new InvalidOperationException("Channel không hợp lệ. Giá trị hợp lệ: 1 (Realtime), 2 (Push).");
            }

            var topFailures = query.TopFailures <= 0 ? 20 : Math.Min(query.TopFailures, 100);

            var deliveryLogsQuery = _context.NotificationDeliveryLogs
                .AsNoTracking()
                .Where(l => l.CreatedDate.HasValue && l.CreatedDate.Value >= from && l.CreatedDate.Value <= to);

            if (channelFilter.HasValue)
            {
                deliveryLogsQuery = deliveryLogsQuery.Where(l => l.Channel == channelFilter.Value);
            }

            var totalAttempts = await deliveryLogsQuery.CountAsync();
            var totalSuccess = await deliveryLogsQuery.CountAsync(l => l.IsSuccess);
            var totalFailed = totalAttempts - totalSuccess;
            var retryAttempts = await deliveryLogsQuery.CountAsync(l => l.AttemptNumber > 1);

            var groupedSuppressedCount = await deliveryLogsQuery.CountAsync(l =>
                l.IsSuccess &&
                l.ErrorMessage != null &&
                l.ErrorMessage.Contains("Grouped by window"));

            var throttledDeferredCount = await deliveryLogsQuery.CountAsync(l =>
                !l.IsSuccess &&
                l.ErrorMessage != null &&
                l.ErrorMessage.Contains("Throttled by window"));

            var delaySecondsQuery = _context.NotificationDeliveryLogs
                .AsNoTracking()
                .Join(
                    _context.Notifications.AsNoTracking(),
                    log => log.NotificationID,
                    notification => notification.NotificationID,
                    (log, notification) => new { log, notification })
                .Where(x =>
                    x.log.IsSuccess &&
                    x.log.CreatedDate.HasValue &&
                    x.log.CreatedDate.Value >= from &&
                    x.log.CreatedDate.Value <= to &&
                    x.notification.CreatedDate.HasValue &&
                    (!channelFilter.HasValue || x.log.Channel == channelFilter.Value))
                .Select(x => EF.Functions.DateDiffSecond(
                    x.notification.CreatedDate!.Value,
                    x.log.CreatedDate!.Value));

            var averageDelaySeconds = await delaySecondsQuery.AverageAsync(v => (double?)v) ?? 0;
            var maxDelaySeconds = await delaySecondsQuery.MaxAsync(v => (int?)v) ?? 0;

            var outboxQuery = _context.NotificationOutboxes.AsNoTracking();
            if (channelFilter.HasValue)
            {
                outboxQuery = outboxQuery.Where(o => o.Channel == channelFilter.Value);
            }

            var pendingOutboxCount = await outboxQuery.CountAsync(o => o.Status == (byte)NotificationOutboxStatus.Pending);
            var processingOutboxCount = await outboxQuery.CountAsync(o => o.Status == (byte)NotificationOutboxStatus.Processing);
            var failedOutboxCount = await outboxQuery.CountAsync(o => o.Status == (byte)NotificationOutboxStatus.Failed);

            var channelMetrics = await deliveryLogsQuery
                .GroupBy(l => l.Channel)
                .Select(g => new NotificationChannelMetricsDto
                {
                    Channel = g.Key,
                    ChannelName = Enum.IsDefined(typeof(NotificationChannel), g.Key)
                        ? ((NotificationChannel)g.Key).ToString()
                        : g.Key.ToString(),
                    Attempts = g.Count(),
                    Success = g.Count(x => x.IsSuccess),
                    Failed = g.Count(x => !x.IsSuccess),
                    SuccessRate = g.Count() == 0
                        ? 0
                        : Math.Round((decimal)g.Count(x => x.IsSuccess) * 100 / g.Count(), 2)
                })
                .OrderBy(x => x.Channel)
                .ToListAsync();

            var recentFailures = await deliveryLogsQuery
                .Where(l => !l.IsSuccess)
                .OrderByDescending(l => l.CreatedDate)
                .Take(topFailures)
                .Select(l => new NotificationFailureLogDto
                {
                    DeliveryLogID = l.DeliveryLogID,
                    OutboxID = l.OutboxID,
                    NotificationID = l.NotificationID,
                    UserID = l.UserID,
                    Channel = l.Channel,
                    ChannelName = Enum.IsDefined(typeof(NotificationChannel), l.Channel)
                        ? ((NotificationChannel)l.Channel).ToString()
                        : l.Channel.ToString(),
                    AttemptNumber = l.AttemptNumber,
                    ErrorMessage = l.ErrorMessage,
                    CreatedDate = l.CreatedDate
                })
                .ToListAsync();

            return new NotificationObservabilityResponseDto
            {
                Summary = new NotificationObservabilitySummaryDto
                {
                    From = from,
                    To = to,
                    TotalAttempts = totalAttempts,
                    TotalSuccess = totalSuccess,
                    TotalFailed = totalFailed,
                    RetryAttempts = retryAttempts,
                    SuccessRate = totalAttempts == 0
                        ? 0
                        : Math.Round((decimal)totalSuccess * 100 / totalAttempts, 2),
                    AverageDelaySeconds = Math.Round(averageDelaySeconds, 2),
                    MaxDelaySeconds = maxDelaySeconds,
                    PendingOutboxCount = pendingOutboxCount,
                    ProcessingOutboxCount = processingOutboxCount,
                    FailedOutboxCount = failedOutboxCount,
                    GroupedSuppressedCount = groupedSuppressedCount,
                    ThrottledDeferredCount = throttledDeferredCount
                },
                ChannelMetrics = channelMetrics,
                RecentFailures = recentFailures
            };
        }

        /// <summary>
        /// Lấy thống kê điểm danh của một sự kiện
        /// 
        /// LÝ DO SỬ DỤNG DATABASE VIEW (vw_EventAttendanceStats):
        /// 
        /// 1. HIỆU NĂNG:
        ///    - View đã được tối ưu với index phù hợp
        ///    - Các phép COUNT, SUM được xử lý sẵn ở DB
        ///    - Tránh JOIN nhiều bảng ở tầng application
        /// 
        /// 2. TÍNH NHẤT QUÁN:
        ///    - Công thức tính toán chỉ định nghĩa tại một nơi
        ///    - Tránh sai lệch số liệu giữa các API khác nhau
        /// 
        /// 3. KHẢ NĂNG BẢO TRÌ:
        ///    - Khi thay đổi nghiệp vụ, chỉ cần sửa view
        ///    - Không cần chỉnh sửa nhiều đoạn code LINQ
        /// 
        /// 4. BẢO MẬT & KIỂM SOÁT:
        ///    - Có thể phân quyền truy cập view ở DB level
        ///    - Ẩn các truy vấn phức tạp khỏi tầng application
        /// </summary>
        public async Task<EventAttendanceStatsDto> GetEventAttendanceStatsAsync(int eventId, int? unitId = null, int? instituteId = null)
        {
            try
            {
                var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);
                if (scopeInstituteId.HasValue)
                {
                    var eventInstituteId = await _context.Events
                        .Where(e => e.EventID == eventId)
                        .Select(e => e.InstituteID)
                        .FirstOrDefaultAsync();

                    if (eventInstituteId == null)
                    {
                        throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
                    }

                    if (eventInstituteId != scopeInstituteId.Value)
                    {
                        throw new UnauthorizedAccessException("Bạn không có quyền xem báo cáo của sự kiện thuộc viện khác");
                    }
                }

                // Query từ view để lấy stats
                var stats = await _context.Database
                    .SqlQuery<EventAttendanceStatsDto>(
                        $@"SELECT 
                        EventID,
                        EventName,
                        StartTime,
                        MaxParticipants,
                        ISNULL(TotalRegistrations, 0) AS TotalRegistrations,
                        ISNULL(ValidAttendances, 0) AS ValidAttendances,
                        ISNULL(InvalidAttendances, 0) AS InvalidAttendances,
                        ISNULL(AttendanceRate, 0) AS AttendanceRate
                    FROM vw_EventAttendanceStats
                    WHERE EventID = {eventId}")
                    .FirstOrDefaultAsync();

                if (stats == null)
                {
                    // Event không tồn tại hoặc chưa có data
                    var eventExists = await _context.Events.AnyAsync(e => e.EventID == eventId);

                    if (!eventExists)
                    {
                        throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
                    }

                    // Event tồn tại nhưng chưa có đăng ký / điểm danh
                    var eventEntity = await _context.Events.FindAsync(eventId);

                    return new EventAttendanceStatsDto
                    {
                        EventID = eventId,
                        EventName = eventEntity!.EventName,
                        StartTime = DateTimeHelper.ToVietnamTime(eventEntity.StartTime),
                        MaxParticipants = eventEntity.MaxParticipants,
                        TotalRegistrations = 0,
                        ValidAttendances = 0,
                        InvalidAttendances = 0,
                        AttendanceRate = 0
                    };
                }

                _logger.LogInformation(
                    "Lấy thống kê điểm danh thành công cho Event {EventId}: " +
                    "Registrations {Registrations}, Valid {Valid}, Invalid {Invalid}, Rate {Rate}%",
                    eventId, stats.TotalRegistrations, stats.ValidAttendances,
                    stats.InvalidAttendances, stats.AttendanceRate);

                return stats;
            }
            catch (KeyNotFoundException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy thống kê điểm danh của Event {EventId}", eventId);
                throw;
            }
        }
        /// <summary>
        /// Lấy danh sách chi tiết người đã điểm danh của một sự kiện
        /// 
        /// MỤC ĐÍCH SỬ DỤNG:
        /// - Admin / Cán bộ kiểm tra danh sách check-in
        /// - Đối soát dữ liệu điểm danh
        /// - Phát hiện các lượt điểm danh không hợp lệ
        /// 
        /// LƯU Ý HIỆU NĂNG:
        /// - Dữ liệu có thể lớn với sự kiện đông người
        /// - Nên bổ sung phân trang khi số lượng bản ghi tăng cao
        /// </summary>
        public async Task<EventAttendancesListResponseDto> GetEventAttendancesAsync(
            int eventId,
            GetEventAttendancesQueryDto query,
            int? unitId = null,
            int? instituteId = null)
        {
            try
            {
                var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);
                if (scopeInstituteId.HasValue)
                {
                    var eventInstituteId = await _context.Events
                        .Where(e => e.EventID == eventId)
                        .Select(e => e.InstituteID)
                        .FirstOrDefaultAsync();

                    if (eventInstituteId == null)
                    {
                        throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
                    }

                    if (eventInstituteId != scopeInstituteId.Value)
                    {
                        throw new UnauthorizedAccessException("Bạn không có quyền xem danh sách điểm danh của sự kiện thuộc viện khác");
                    }
                }

                // Verify event exists
                var eventExists = await _context.Events.AnyAsync(e => e.EventID == eventId);

                if (!eventExists)
                {
                    throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
                }

                var pageNumber = query.PageNumber < 1 ? 1 : query.PageNumber;
                var pageSize = query.PageSize is < 1 or > 200 ? 50 : query.PageSize;

                var q = string.IsNullOrWhiteSpace(query.Q) ? null : query.Q.Trim();
                var sortBy = string.IsNullOrWhiteSpace(query.SortBy) ? "checkInTime" : query.SortBy.Trim();
                var sortDir = string.IsNullOrWhiteSpace(query.SortDir) ? "asc" : query.SortDir.Trim();

                var baseQuery = _context.Attendances
                    .AsNoTracking()
                    .Where(a => a.EventID == eventId)
                    .Where(a => !query.IsValid.HasValue || a.IsValid == query.IsValid.Value)
                    .Where(a => query.From == null || (a.CheckInTime.HasValue && a.CheckInTime.Value >= query.From.Value))
                    .Where(a => query.To == null || (a.CheckInTime.HasValue && a.CheckInTime.Value <= query.To.Value));

                if (query.FaceVerified.HasValue)
                {
                    baseQuery = baseQuery.Where(a => a.FaceVerified == query.FaceVerified.Value);
                }

                if (!string.IsNullOrWhiteSpace(query.FaceVerificationStatus))
                {
                    var faceVerificationStatus = query.FaceVerificationStatus.Trim();
                    baseQuery = baseQuery.Where(a => a.FaceVerificationStatus == faceVerificationStatus);
                }

                if (!string.IsNullOrWhiteSpace(query.RiskLevel))
                {
                    var riskLevel = query.RiskLevel.Trim();
                    baseQuery = baseQuery.Where(a => a.RiskLevel == riskLevel);
                }

                if (query.SuspiciousOnly == true)
                {
                    baseQuery = baseQuery.Where(a => a.RiskScore.HasValue && a.RiskScore.Value > 0);
                }

                if (!string.IsNullOrWhiteSpace(query.Method))
                {
                    var method = query.Method.Trim();
                    baseQuery = baseQuery.Where(a => a.CheckInMethod == method);
                }

                if (q != null)
                {
                    baseQuery = baseQuery.Where(a =>
                        a.User != null &&
                        (a.User.FullName.Contains(q) ||
                         a.User.Code.StartsWith(q) ||
                         a.User.Email.StartsWith(q)));
                }

                var counts = await baseQuery
                    .GroupBy(_ => 1)
                    .Select(g => new
                    {
                        Total = g.Count(),
                        Valid = g.Count(x => x.IsValid == true),
                        Invalid = g.Count(x => x.IsValid != true)
                    })
                    .FirstOrDefaultAsync();

                var totalCount = counts?.Total ?? 0;

                // Sort (whitelist)
                IOrderedQueryable<Domain.Entities.Attendance> orderedQuery;
                var isDesc = sortDir.Equals("desc", StringComparison.OrdinalIgnoreCase);

                switch (sortBy.ToLowerInvariant())
                {
                    case "code":
                        orderedQuery = isDesc
                            ? baseQuery.OrderByDescending(a => a.User!.Code).ThenByDescending(a => a.AttendanceID)
                            : baseQuery.OrderBy(a => a.User!.Code).ThenBy(a => a.AttendanceID);
                        break;

                    case "fullname":
                        orderedQuery = isDesc
                            ? baseQuery.OrderByDescending(a => a.User!.FullName).ThenByDescending(a => a.AttendanceID)
                            : baseQuery.OrderBy(a => a.User!.FullName).ThenBy(a => a.AttendanceID);
                        break;

                    case "isvalid":
                        orderedQuery = isDesc
                            ? baseQuery.OrderByDescending(a => a.IsValid).ThenByDescending(a => a.AttendanceID)
                            : baseQuery.OrderBy(a => a.IsValid).ThenBy(a => a.AttendanceID);
                        break;

                    case "checkintime":
                    default:
                        orderedQuery = isDesc
                            ? baseQuery.OrderByDescending(a => a.CheckInTime).ThenByDescending(a => a.AttendanceID)
                            : baseQuery.OrderBy(a => a.CheckInTime).ThenBy(a => a.AttendanceID);
                        break;
                }

                var rawItems = await orderedQuery
                    .Skip((pageNumber - 1) * pageSize)
                    .Take(pageSize)
                    .Select(a => new
                    {
                        a.AttendanceID,
                        a.UserID,
                        FullName = a.User!.FullName,
                        Code = a.User!.Code,
                        Email = a.User!.Email,
                        a.CheckInTime,
                        a.CheckInMethod,
                        a.IsValid,
                        a.InvalidReason,
                        a.Distance,
                        a.UserLatitude,
                        a.UserLongitude,
                        a.IPAddress,
                        a.DeviceInfo,
                        a.ClientDeviceId,
                        a.FaceVerified,
                        a.FaceConfidence,
                        a.FaceVerificationStatus,
                        a.FaceVerificationProvider,
                        a.FaceVerificationVersion,
                        a.FaceVerificationReason,
                        a.LivenessPassed,
                        a.LivenessScore,
                        a.LivenessReason,
                        a.RiskScore,
                        a.RiskLevel,
                        a.RiskReasonsJson
                    })
                    .ToListAsync();

                var items = rawItems
                    .Select(a => new AttendanceDetailDto
                    {
                        AttendanceID = a.AttendanceID,
                        UserID = a.UserID,
                        FullName = a.FullName,
                        Code = a.Code,
                        Email = a.Email,
                        CheckInTime = a.CheckInTime.HasValue
                            ? DateTimeHelper.ToVietnamTime(a.CheckInTime.Value)
                            : null,
                        CheckInMethod = a.CheckInMethod,
                        IsValid = a.IsValid,
                        InvalidReason = a.InvalidReason,
                        Distance = a.Distance,
                        UserLatitude = a.UserLatitude,
                        UserLongitude = a.UserLongitude,
                        IPAddress = a.IPAddress,
                        DeviceInfo = a.DeviceInfo,
                        ClientDeviceId = a.ClientDeviceId,
                        FaceVerified = string.IsNullOrWhiteSpace(a.FaceVerificationStatus) ? null : a.FaceVerified,
                        FaceConfidence = a.FaceConfidence,
                        FaceVerificationStatus = a.FaceVerificationStatus,
                        FaceVerificationProvider = a.FaceVerificationProvider,
                        FaceVerificationVersion = a.FaceVerificationVersion,
                        FaceVerificationReason = a.FaceVerificationReason,
                        LivenessPassed = a.LivenessPassed,
                        LivenessScore = a.LivenessScore,
                        LivenessReason = a.LivenessReason,
                        RiskScore = a.RiskScore,
                        RiskLevel = a.RiskLevel,
                        RiskReasons = ParseRiskReasons(a.RiskReasonsJson)
                    })
                    .ToList();

                _logger.LogInformation(
                    "Retrieved {Count}/{Total} attendance records for Event {EventId} (page {PageNumber}, size {PageSize})",
                    items.Count,
                    totalCount,
                    eventId,
                    pageNumber,
                    pageSize);

                return new EventAttendancesListResponseDto
                {
                    EventId = eventId,
                    Summary = new EventAttendancesSummaryDto
                    {
                        TotalRecords = totalCount,
                        ValidCount = counts?.Valid ?? 0,
                        InvalidCount = counts?.Invalid ?? 0
                    },
                    Attendances = new PaginatedResultDto<AttendanceDetailDto>
                    {
                        Items = items,
                        TotalCount = totalCount,
                        PageNumber = pageNumber,
                        PageSize = pageSize
                    }
                };
            }
            catch (KeyNotFoundException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách điểm danh của Event {EventId}", eventId);
                throw;
            }
        }

        /// <summary>
        /// Lấy thống kê tổng hợp của tất cả các sự kiện
        /// 
        /// MỤC ĐÍCH SỬ DỤNG:
        /// - Dashboard tổng quan cho Admin
        /// - So sánh hiệu quả tổ chức các sự kiện
        /// - Phục vụ báo cáo cho lãnh đạo
        /// 
        /// HIỆU NĂNG:
        /// - Sử dụng database view để lấy số liệu thống kê
        /// - Có thể bổ sung cache (5–10 phút) nếu dữ liệu lớn
        /// </summary>
        public async Task<AllEventsAttendanceStatsResponseDto> GetAllEventsAttendanceStatsAsync(
            GetAllEventsAttendanceStatsQueryDto query,
            int? unitId = null,
            int? instituteId = null)
        {
            try
            {
                var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);

                var pageNumber = query.PageNumber < 1 ? 1 : query.PageNumber;
                var pageSize = query.PageSize is < 1 or > 200 ? 20 : query.PageSize;

                var q = string.IsNullOrWhiteSpace(query.Q) ? null : query.Q.Trim();
                var sortBy = string.IsNullOrWhiteSpace(query.SortBy) ? "startTime" : query.SortBy.Trim();
                var sortDir = string.IsNullOrWhiteSpace(query.SortDir) ? "desc" : query.SortDir.Trim();

                var eventsQuery = _context.Events
                    .AsNoTracking()
                    .Where(e => !scopeInstituteId.HasValue || e.InstituteID == scopeInstituteId.Value);

                if (query.Status.HasValue)
                {
                    eventsQuery = eventsQuery.Where(e => e.Status == query.Status.Value);
                }

                if (query.From.HasValue)
                {
                    eventsQuery = eventsQuery.Where(e => e.StartTime >= query.From.Value);
                }

                if (query.To.HasValue)
                {
                    eventsQuery = eventsQuery.Where(e => e.StartTime <= query.To.Value);
                }

                if (q != null)
                {
                    eventsQuery = eventsQuery.Where(e => e.EventName.Contains(q));
                }

                var allEvents = await eventsQuery
                    .Select(e => new
                    {
                        e.EventID,
                        e.Status
                    })
                    .ToListAsync();

                // Get stats from view
                var statsFromView = await _context.Database
                    .SqlQuery<EventStatsListItemDto>(
                        $@"SELECT 
                        EventID,
                        EventName,
                        StartTime,
                        '' AS Status,
                        MaxParticipants,
                        ISNULL(TotalRegistrations, 0) AS TotalRegistrations,
                        ISNULL(ValidAttendances, 0) AS ValidAttendances,
                        ISNULL(InvalidAttendances, 0) AS InvalidAttendances,
                        ISNULL(AttendanceRate, 0) AS AttendanceRate,
                        0 AS NotCheckedIn
                    FROM vw_EventAttendanceStats
                    ORDER BY StartTime DESC")
                    .ToListAsync();

                var allowedEventIds = allEvents.Select(e => e.EventID).ToHashSet();
                statsFromView = statsFromView.Where(s => allowedEventIds.Contains(s.EventID)).ToList();

                // ================================================================
                // GỘP TRẠNG THÁI SỰ KIỆN VÀ TÍNH SỐ CHƯA ĐIỂM DANH
                // ================================================================
                var eventStatusByEventId = allEvents.ToDictionary(e => e.EventID, e => e.Status ?? 0);
                var merged = statsFromView.Select(stat =>
                {
                    stat.Status = eventStatusByEventId.TryGetValue(stat.EventID, out var status)
                        ? ((EventStatus)status).ToString()
                        : ((EventStatus)0).ToString();
                    stat.NotCheckedIn = stat.TotalRegistrations -
                        (stat.ValidAttendances + stat.InvalidAttendances);

                    return stat;
                }).ToList();

                // ================================================================
                // SORT (whitelist)
                // ================================================================
                var isDesc = sortDir.Equals("desc", StringComparison.OrdinalIgnoreCase);
                IEnumerable<EventStatsListItemDto> ordered;

                switch (sortBy.ToLowerInvariant())
                {
                    case "attendancerate":
                        ordered = isDesc
                            ? merged.OrderByDescending(x => x.AttendanceRate).ThenByDescending(x => x.EventID)
                            : merged.OrderBy(x => x.AttendanceRate).ThenBy(x => x.EventID);
                        break;

                    case "totalregistrations":
                        ordered = isDesc
                            ? merged.OrderByDescending(x => x.TotalRegistrations).ThenByDescending(x => x.EventID)
                            : merged.OrderBy(x => x.TotalRegistrations).ThenBy(x => x.EventID);
                        break;

                    case "validattendances":
                        ordered = isDesc
                            ? merged.OrderByDescending(x => x.ValidAttendances).ThenByDescending(x => x.EventID)
                            : merged.OrderBy(x => x.ValidAttendances).ThenBy(x => x.EventID);
                        break;

                    case "invalidattendances":
                        ordered = isDesc
                            ? merged.OrderByDescending(x => x.InvalidAttendances).ThenByDescending(x => x.EventID)
                            : merged.OrderBy(x => x.InvalidAttendances).ThenBy(x => x.EventID);
                        break;

                    case "notcheckedin":
                        ordered = isDesc
                            ? merged.OrderByDescending(x => x.NotCheckedIn).ThenByDescending(x => x.EventID)
                            : merged.OrderBy(x => x.NotCheckedIn).ThenBy(x => x.EventID);
                        break;

                    case "eventname":
                        ordered = isDesc
                            ? merged.OrderByDescending(x => x.EventName).ThenByDescending(x => x.EventID)
                            : merged.OrderBy(x => x.EventName).ThenBy(x => x.EventID);
                        break;

                    case "starttime":
                    default:
                        ordered = isDesc
                            ? merged.OrderByDescending(x => x.StartTime).ThenByDescending(x => x.EventID)
                            : merged.OrderBy(x => x.StartTime).ThenBy(x => x.EventID);
                        break;
                }

                var totalCount = merged.Count;
                var pageItems = ordered
                    .Skip((pageNumber - 1) * pageSize)
                    .Take(pageSize)
                    .ToList();

                var averageAttendanceRate = merged.Any()
                    ? merged.Average(s => s.AttendanceRate)
                    : 0;

                var response = new AllEventsAttendanceStatsResponseDto
                {
                    Summary = new AllEventsAttendanceStatsSummaryDto
                    {
                        TotalEvents = totalCount,
                        TotalRegistrations = merged.Sum(s => s.TotalRegistrations),
                        TotalValidAttendances = merged.Sum(s => s.ValidAttendances),
                        TotalInvalidAttendances = merged.Sum(s => s.InvalidAttendances),
                        AverageAttendanceRate = averageAttendanceRate
                    },
                    Pagination = new PaginationMetaDto
                    {
                        TotalCount = totalCount,
                        PageNumber = pageNumber,
                        PageSize = pageSize,
                        TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
                        HasPreviousPage = pageNumber > 1,
                        HasNextPage = pageNumber < (int)Math.Ceiling(totalCount / (double)pageSize)
                    },
                    Items = pageItems
                };

                _logger.LogInformation(
                    "Retrieved stats for {Count} events",
                    pageItems.Count);

                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy thống kê tổng hợp các sự kiện");
                throw;
            }
        }

        private static List<string> ParseRiskReasons(string? riskReasonsJson)
        {
            if (string.IsNullOrWhiteSpace(riskReasonsJson))
            {
                return new List<string>();
            }

            try
            {
                var parsed = JsonSerializer.Deserialize<List<AttendanceRiskReasonDto>>(riskReasonsJson);
                return parsed?
                    .Where(reason => !string.IsNullOrWhiteSpace(reason.Description))
                    .Select(reason => reason.Description!.Trim())
                    .ToList()
                    ?? new List<string>();
            }
            catch
            {
                return new List<string>();
            }
        }

        private async Task<int?> ResolveInstituteScopeAsync(int? instituteId, int? unitId)
        {
            if (instituteId.HasValue)
            {
                return instituteId.Value;
            }

            if (!unitId.HasValue)
            {
                return null;
            }

            var resolvedInstituteId = await _context.Units
                .Where(u => u.UnitID == unitId.Value)
                .Select(u => u.InstituteID)
                .FirstOrDefaultAsync();

            if (resolvedInstituteId == 0)
            {
                throw new UnauthorizedAccessException("unitId trong token không hợp lệ");
            }

            return resolvedInstituteId;
        }

    }
}

