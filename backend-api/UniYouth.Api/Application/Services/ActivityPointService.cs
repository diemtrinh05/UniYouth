using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Points;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;
using UniYouth.Api.Shared.Exceptions;
using UniYouth.Api.Shared.Helpers;
using Microsoft.Data.SqlClient;

namespace UniYouth.Api.Application.Services
{
    public interface IActivityPointService
    {
        Task<PointAwardedDto?> AwardPointsForAttendanceAsync(int eventId, int userId, int attendanceId);
        Task<UserPointSummaryDto> GetUserPointSummaryAsync(int userId);
        Task<UniYouth.Api.Contracts.DTOs.Common.PaginatedResultDto<PointHistoryItemDto>> GetUserPointHistoryAsync(int userId, int pageNumber, int pageSize);
    }
    /// <summary>
    /// Service xử lý toàn bộ nghiệp vụ liên quan đến điểm rèn luyện
    /// 
    /// PHẠM VI:
    /// - Cộng điểm tự động khi điểm danh hợp lệ
    /// - Lấy tổng hợp điểm của người dùng
    /// - Lấy lịch sử cộng / trừ điểm
    /// 
    /// NGUYÊN TẮC:
    /// - Không xử lý nghiệp vụ ở Controller
    /// - Logic cộng điểm phải đảm bảo không bị trùng lặp
    /// - Ưu tiên tính nhất quán và khả năng audit
    /// </summary>
    public class ActivityPointService : IActivityPointService
    {
        private readonly UniYouthDbContext _context;
        private readonly ILogger<ActivityPointService> _logger;

        public ActivityPointService(
            UniYouthDbContext context,
            ILogger<ActivityPointService> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Tự động cộng điểm sau khi người dùng điểm danh hợp lệ
        /// 
        /// LÝ DO CHỈ CỘNG ĐIỂM KHI ATTENDANCE HỢP LỆ:
        /// - Chỉ những lượt điểm danh hợp lệ (IsValid = true) mới được tính điểm
        /// - Các trường hợp không hợp lệ (ngoài phạm vi GPS, sai điều kiện, v.v.)
        ///   vẫn được lưu để audit nhưng KHÔNG được cộng điểm
        /// - Đảm bảo tính công bằng cho người tham gia sự kiện
        /// 
        /// CHỐNG CỘNG ĐIỂM TRÙNG:
        /// - Mỗi (EventID, UserID) chỉ được cộng điểm MỘT LẦN
        /// - Method này có tính idempotent: gọi nhiều lần cũng không cộng trùng
        /// 
        /// LƯU Ý VỀ TRANSACTION:
        /// - Method này được gọi bên trong transaction của AttendanceService
        /// - Attendance là nghiệp vụ bắt buộc
        /// - Cộng điểm là nghiệp vụ phụ (best-effort)
        /// </summary>
        public async Task<PointAwardedDto?> AwardPointsForAttendanceAsync(
            int eventId,
            int userId,
            int attendanceId)
        {
            try
            {
                // ================================================================
                // STEP 1: KIỂM TRA ĐÃ ĐƯỢC CỘNG ĐIỂM HAY CHƯA (CHỐNG TRÙNG)
                // ================================================================
                var existingPoints = await _context.ActivityPoints
                    .Where(ap =>
                        ap.EventID == eventId &&
                        ap.UserID == userId &&
                        ap.PointType == PointTypeEnum.Attendance.ToString())
                    .FirstOrDefaultAsync();

                if (existingPoints != null)
                {
                    _logger.LogInformation(
                        "Người dùng đã được cộng điểm cho Event {EventId} User {UserId}",
                        eventId, userId);

                    // Conflict (409): đã tồn tại điểm Attendance cho (EventID, UserID)
                    throw new ConflictException("Điểm điểm danh cho sự kiện này đã được cộng trước đó.");
                }

                // ================================================================
                // STEP 2: LẤY CẤU HÌNH ĐIỂM CỦA SỰ KIỆN
                // ================================================================
                // Default: tất cả user là Participant (người tham gia)
                // Future: có thể check role cụ thể của user trong event
                var eventPoints = await _context.EventPoints
                    .Where(ep => ep.EventID == eventId && ep.RoleType == EventRoleTypeEnum.Participant.ToString())
                    .FirstOrDefaultAsync();

                if (eventPoints == null)
                {
                    _logger.LogWarning(
                        "No EventPoints defined for Event {EventId} RoleType Participant",
                        eventId);

                    // Không có định nghĩa điểm = không cộng
                    return null;
                }

                // ================================================================
                // STEP 3: TẠO BẢN GHI ACTIVITY POINT
                // ================================================================
                var activityPoints = new ActivityPoint
                {
                    EventID = eventId,
                    UserID = userId,
                    EventPointID = eventPoints.EventPointID,
                    Points = eventPoints.Points,
                    PointType = PointTypeEnum.Attendance.ToString(),
                    AwardedBy = null, // NULL = automatic
                    CreatedDate = DateTime.Now
                };

                _context.ActivityPoints.Add(activityPoints);
                try
                {
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateException ex) when (IsUniqueAttendancePointsConflict(ex))
                {
                    // DB UNIQUE (filtered) constraint đảm bảo chống cộng điểm trùng trong race condition
                    throw new ConflictException("Điểm điểm danh cho sự kiện này đã được cộng trước đó.");
                }

                _logger.LogInformation(
                    "Cộng điểm thành công: Event {EventId}, User {UserId}, Points {Points}, " +
                    "AttendanceId {AttendanceId}",
                    eventId, userId, eventPoints.Points, attendanceId);

                // ================================================================
                // STEP 4: TÍNH TỔNG ĐIỂM HIỆN TẠI CỦA NGƯỜI DÙNG
                // ================================================================
                var totalPoints = await _context.ActivityPoints
                    .Where(ap => ap.UserID == userId)
                    .SumAsync(ap => ap.Points);

                // ================================================================
                // STEP 5: TRẢ KẾT QUẢ
                // ================================================================
                return new PointAwardedDto
                {
                    Points = eventPoints.Points,
                    PointType = PointTypeEnum.Attendance.ToString(),
                    RoleType = EventRoleTypeEnum.Participant.ToString(),
                    CurrentTotalPoints = totalPoints
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Lỗi khi cộng điểm tự động: Event {EventId}, User {UserId}",
                    eventId, userId);

                // Rethrow để transaction rollback
                throw;
            }
        }

        /// <summary>
        /// Lấy thông tin tổng hợp điểm rèn luyện của người dùng
        ///
        /// QUY ƯỚC NGHIỆP VỤ:
        /// - TotalPoints       : tổng tất cả ActivityPoints của user
        /// - EventsParticipated: số sự kiện DISTINCT mà user đã có bản ghi ActivityPoints
        /// - ValidAttendances  : số lượt điểm danh hợp lệ (Attendance.IsValid = true)
        /// </summary>
        public async Task<UserPointSummaryDto> GetUserPointSummaryAsync(int userId)
        {
            var user = await _context.Users
                .AsNoTracking()
                .Where(u => u.UserID == userId)
                .Select(u => new
                {
                    u.UserID,
                    u.FullName,
                    u.Code
                })
                .FirstOrDefaultAsync();

            if (user == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy người dùng với ID {userId}");
            }

            var totalPoints = await _context.ActivityPoints
                .AsNoTracking()
                .Where(ap => ap.UserID == userId)
                .SumAsync(ap => (int?)ap.Points) ?? 0;

            var eventsParticipated = await _context.ActivityPoints
                .AsNoTracking()
                .Where(ap => ap.UserID == userId)
                .Select(ap => ap.EventID)
                .Distinct()
                .CountAsync();

            var validAttendanceCount = await _context.Attendances
                .AsNoTracking()
                .Where(a => a.UserID == userId && a.IsValid == true)
                .CountAsync();

            return new UserPointSummaryDto
            {
                TotalPoints = totalPoints,
                EventsParticipated = eventsParticipated,
                ValidAttendances = validAttendanceCount,
                FullName = user.FullName,
                Code = user.Code
            };
        }
        /// <summary>
        /// Lấy lịch sử cộng điểm chi tiết của người dùng
        /// 
        /// USE CASE:
        /// - User xem lịch sử điểm của mình
        /// - Mobile app: Points history screen
        /// - Web app: Profile page
        /// - Verify point calculations
        /// 
        /// DISPLAY:
        /// - Show newest first (ORDER BY CreatedDate DESC)
        /// - Include event name and date
        /// - Show point type (Attendance/Bonus/Penalty)
        /// - Show who awarded (if manual)
        /// 
        /// PERFORMANCE:
        /// - JOINs with Events and Users tables
        /// - Consider pagination for users with many records
        /// - Index on (UserID, CreatedDate) recommended
        /// </summary>
        public async Task<UniYouth.Api.Contracts.DTOs.Common.PaginatedResultDto<PointHistoryItemDto>> GetUserPointHistoryAsync(int userId, int pageNumber, int pageSize)
        {
            try
            {
                if (pageNumber < 1)
                {
                    pageNumber = 1;
                }

                if (pageSize < 1)
                {
                    pageSize = 20;
                }

                // Verify user exists
                var userExists = await _context.Users.AnyAsync(u => u.UserID == userId);
            
                if (!userExists)
                {
                    throw new KeyNotFoundException($"Không tìm thấy người dùng với ID {userId}");
                }

                var baseQuery = _context.ActivityPoints
                    .Where(ap => ap.UserID == userId)
                    .AsNoTracking();

                var totalCount = await baseQuery.CountAsync();

                // Query point history with event info (paged)
                var items = await baseQuery
                    .OrderByDescending(ap => ap.CreatedDate)
                    .Skip((pageNumber - 1) * pageSize)
                    .Take(pageSize)
                    .Select(ap => new PointHistoryItemDto
                    {
                        PointID = ap.PointID,
                        EventID = ap.EventID,
                        EventName = ap.Event!.EventName,
                        EventStartTime = ap.Event.StartTime,
                        Points = ap.Points,
                        PointType = ap.PointType,
                        RoleType = ap.EventPoint != null 
                            ? ap.EventPoint.RoleType 
                            : null,
                        AwardedByName = ap.AwardedByNavigation != null 
                            ? ap.AwardedByNavigation.FullName 
                            : null,
                        CreatedDate = ap.CreatedDate.HasValue
                            ? DateTimeHelper.ToVietnamTime(ap.CreatedDate.Value)
                            : null
                    })
                    .ToListAsync();

                _logger.LogInformation(
                    "Retrieved {Count} point history records (paged) for User {UserId}",
                    items.Count, userId);

                return new UniYouth.Api.Contracts.DTOs.Common.PaginatedResultDto<PointHistoryItemDto>
                {
                    Items = items,
                    TotalCount = totalCount,
                    PageNumber = pageNumber,
                    PageSize = pageSize
                };
            }
            catch (KeyNotFoundException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy lịch sử điểm của for User {UserId}", userId);
                throw;
            }
        }

        private static bool IsUniqueAttendancePointsConflict(DbUpdateException ex)
        {
            if (ex.InnerException is not SqlException sqlEx)
            {
                return false;
            }

            // SQL Server duplicate key: 2601 (unique index) / 2627 (unique constraint)
            if (sqlEx.Number is 2601 or 2627)
            {
                return true;
            }

            // Fallback theo tên index (trường hợp message có chứa tên index)
            return sqlEx.Message.Contains(
                "UQ_ActivityPoints_Attendance_EventID_UserID",
                StringComparison.OrdinalIgnoreCase);
        }
    }
}

