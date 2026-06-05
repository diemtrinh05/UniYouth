using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Services
{
    public record AttendancePointsSyncResultDto(
        int EventId,
        bool HasParticipantPointConfig,
        int UpdatedCount,
        int InsertedCount);

    public interface IAttendancePointsSyncService
    {
        /// <summary>
        /// Đồng bộ điểm Attendance theo trạng thái hiện tại:
        /// - Nếu EventPoints(Participant) đã có: đảm bảo mọi user có attendance hợp lệ đều có ActivityPoints Attendance
        /// - Nếu điểm Participant thay đổi: cập nhật lại Points cho ActivityPoints Attendance hiện có
        /// </summary>
        Task<AttendancePointsSyncResultDto> SyncAttendancePointsForEventAsync(int eventId, CancellationToken cancellationToken);
    }

    public class AttendancePointsSyncService : IAttendancePointsSyncService
    {
        private readonly UniYouthDbContext _context;
        private readonly ILogger<AttendancePointsSyncService> _logger;

        public AttendancePointsSyncService(
            UniYouthDbContext context,
            ILogger<AttendancePointsSyncService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<AttendancePointsSyncResultDto> SyncAttendancePointsForEventAsync(
            int eventId,
            CancellationToken cancellationToken)
        {
            // 1) Lấy cấu hình điểm Participant cho event
            var eventPoint = await _context.EventPoints
                .AsNoTracking()
                .Where(ep => ep.EventID == eventId && ep.RoleType == EventRoleTypeEnum.Participant.ToString())
                .Select(ep => new { ep.EventPointID, ep.Points })
                .FirstOrDefaultAsync(cancellationToken);

            if (eventPoint == null)
            {
                _logger.LogInformation(
                    "SyncAttendancePointsForEvent skipped: no Participant EventPoints. EventId={EventId}",
                    eventId);

                return new AttendancePointsSyncResultDto(
                    EventId: eventId,
                    HasParticipantPointConfig: false,
                    UpdatedCount: 0,
                    InsertedCount: 0);
            }

            var now = DateTime.Now;

            // 2) Recalculate: cập nhật lại điểm Attendance đã cộng trước đó theo cấu hình hiện tại
            // Chỉ áp dụng cho những user có attendance hợp lệ (IsValid=1) để tránh cập nhật nhầm dữ liệu khác.
            var validUsersQuery = _context.Attendances
                .Where(a => a.EventID == eventId && a.IsValid == true)
                .Select(a => a.UserID)
                .Distinct();

            var updatedCount = await _context.ActivityPoints
                .Where(ap =>
                    ap.EventID == eventId &&
                    ap.PointType == PointTypeEnum.Attendance.ToString() &&
                    validUsersQuery.Contains(ap.UserID) &&
                    (ap.Points != eventPoint.Points || ap.EventPointID != eventPoint.EventPointID))
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(ap => ap.Points, eventPoint.Points)
                    .SetProperty(ap => ap.EventPointID, eventPoint.EventPointID), cancellationToken);

            // 3) Backfill: insert missing ActivityPoints Attendance cho các user đã attendance hợp lệ
            // Dùng SQL set-based để tối ưu hiệu năng + đảm bảo idempotent (NOT EXISTS).
            var insertedCount = 0;
            try
            {
                insertedCount = await _context.Database.ExecuteSqlInterpolatedAsync($@"
INSERT INTO dbo.ActivityPoints (EventID, UserID, EventPointID, Points, PointType, AwardedBy, CreatedDate)
SELECT {eventId}, v.UserID, {eventPoint.EventPointID}, {eventPoint.Points}, N'{PointTypeEnum.Attendance}', NULL, {now}
FROM (
    SELECT DISTINCT a.UserID
    FROM dbo.Attendances a
    WHERE a.EventID = {eventId} AND a.IsValid = 1
) v
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.ActivityPoints ap
    WHERE ap.EventID = {eventId} AND ap.UserID = v.UserID AND ap.PointType = N'{PointTypeEnum.Attendance}'
);
", cancellationToken);
            }
            catch (SqlException ex) when (ex.Number is 2601 or 2627)
            {
                // Trường hợp race condition hiếm gặp: concurrent insert cùng lúc.
                // Idempotent: có thể bỏ qua và job lần sau sẽ đồng bộ lại.
                _logger.LogWarning(ex,
                    "SyncAttendancePointsForEvent insert conflict (unique). EventId={EventId}",
                    eventId);
            }

            _logger.LogInformation(
                "SyncAttendancePointsForEvent done: EventId={EventId}, Updated={Updated}, Inserted={Inserted}",
                eventId, updatedCount, insertedCount);

            return new AttendancePointsSyncResultDto(
                EventId: eventId,
                HasParticipantPointConfig: true,
                UpdatedCount: updatedCount,
                InsertedCount: insertedCount);
        }
    }
}

