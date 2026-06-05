using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events;
using UniYouth.Api.Contracts.DTOs.Events.Points;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Application.Jobs;
using UniYouth.Api.Shared.Helpers;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Services
{
    /// <summary>
    /// Service quản lý cấu hình Điểm Sự Kiện.
    /// 
    /// TẠI SAO EVENTPOINTS CÓ THỂ CẤU HÌNH:
    /// - Các sự kiện khác nhau có mức độ quan trọng khác nhau
    /// - Tổ chức có thể muốn khuyến khích các vai trò nhất định (ví dụ: tình nguyện viên nhận điểm thưởng)
    /// - Giá trị điểm có thể thay đổi theo thời gian dựa trên chính sách của trường
    /// - Cho phép hệ thống khen thưởng linh hoạt mà không cần thay đổi code
    /// 
    /// CÁCH ROLETYPE ẢNH HƯỞNG ĐÕN VIỆC TRAO ĐIỂM:
    /// - Khi người dùng điểm danh vào sự kiện (bảng Attendances), hệ thống tra cứu
    ///   EventPointID của họ để xác định vai trò
    /// - Sau đó hệ thống truy vấn EventPoints để tìm cặp (EventID, RoleType) phù hợp
    /// - Điểm từ EventPoints tự động được thêm vào bảng ActivityPoints
    /// - Điều này cho phép: Ban tổ chức (50 điểm), Người tham gia (10 điểm), Tình nguyện viên (20 điểm) cho cùng một sự kiện
    /// </summary>
    public interface IEventPointService
    {
        Task<IEnumerable<EventPointDto>> GetEventPointsAsync(int eventId);
        Task<EventPointDto> CreateEventPointAsync(int eventId, CreateEventPointRequestDto request, int actorUserId);
        Task<EventPointDto> UpdateEventPointAsync(int eventPointId, UpdateEventPointRequestDto request, int actorUserId);
        Task DeleteEventPointAsync(int eventPointId, int actorUserId);
        Task<int?> GetPointsForRoleAsync(int eventId, string roleType);
    }
    public class EventPointService : IEventPointService
    {
        private readonly UniYouthDbContext _context;
        private readonly INotificationService _notificationService;
        private readonly IAttendancePointsSyncQueue _attendancePointsSyncQueue;
        private readonly ILogger<EventPointService> _logger;

        // Các loại vai trò hợp lệ - tập trung để đảm bảo tính nhất quán
        private static readonly HashSet<string> ValidRoleTypes = new()
        {
        "Organizer",
        "Participant",
        "Volunteer"
        };

        public EventPointService(
            UniYouthDbContext context,
            INotificationService notificationService,
            IAttendancePointsSyncQueue attendancePointsSyncQueue,
            ILogger<EventPointService> logger)
        {
            _context = context;
            _notificationService = notificationService;
            _attendancePointsSyncQueue = attendancePointsSyncQueue;
            _logger = logger;
        }

        /// <summary>
        /// Lấy tất cả cấu hình điểm cho một sự kiện cụ thể
        /// </summary>
        public async Task<IEnumerable<EventPointDto>> GetEventPointsAsync(int eventId)
        {
            // Kiểm tra sự kiện có tồn tại không
            var eventExists = await _context.Events
                .AnyAsync(e => e.EventID == eventId);

            if (!eventExists)
            {
                throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
            }

            // Truy vấn danh sách cấu hình điểm theo EventID
            var eventPoints = await _context.EventPoints
                .Where(ep => ep.EventID == eventId)
                .OrderBy(ep => ep.RoleType)
                .Select(ep => new EventPointDto
                {
                    EventPointID = ep.EventPointID,
                    EventID = ep.EventID,
                    RoleType = ep.RoleType,
                    Points = ep.Points,
                    Description = ep.Description,
                    CreatedDate = ep.CreatedDate.HasValue
                                ? DateTimeHelper.ToVietnamTime(ep.CreatedDate.Value)
                                : null
                })
                .ToListAsync();

            return eventPoints;
        }

        /// <summary>
        /// Tạo cấu hình điểm mới cho một sự kiện
        /// </summary>
        public async Task<EventPointDto> CreateEventPointAsync(
            int eventId,
            CreateEventPointRequestDto request,
            int actorUserId)
        {
            // 1. Kiểm tra sự kiện có tồn tại không
            var eventEntity = await _context.Events
                .AsNoTracking()
                .Where(e => e.EventID == eventId)
                .Select(e => new { e.EventID, e.EventName })
                .FirstOrDefaultAsync();

            if (eventEntity == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
            }

            // 2. Kiểm tra RoleType hợp lệ
            if (!ValidRoleTypes.Contains(request.RoleType))
            {
                throw new ArgumentException(
                    $"RoleType không hợp lệ. Phải là một trong: {string.Join(", ", ValidRoleTypes)}");
            }

            // 3. Kiểm tra trùng lặp (EventID, RoleType)
            var duplicateExists = await _context.EventPoints
                .AnyAsync(ep => ep.EventID == eventId && ep.RoleType == request.RoleType);

            if (duplicateExists)
            {
                throw new InvalidOperationException(
                    $"Cấu hình điểm cho RoleType '{request.RoleType}' đã tồn tại cho sự kiện này");
            }

            // 4. Tạo entity EventPoint mới
            var eventPoint = new EventPoint
            {
                EventID = eventId,
                RoleType = request.RoleType,
                Points = request.Points,
                Description = request.Description,
                CreatedDate = DateTime.Now
            };

            _context.EventPoints.Add(eventPoint);
            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Đã tạo cấu hình điểm sự kiện: EventID={EventId}, RoleType={RoleType}, Points={Points}",
                eventId, request.RoleType, request.Points);

            // Đồng bộ điểm Attendance nếu vừa cấu hình Participant (cộng bù + recalculation)
            if (request.RoleType == EventRoleTypeEnum.Participant.ToString())
            {
                _attendancePointsSyncQueue.Enqueue(eventId);
            }

            try
            {
                await _notificationService.CreateActorEventPointActionConfirmationAsync(
                    actorUserId,
                    eventEntity.EventID,
                    eventEntity.EventName,
                    eventPoint.RoleType,
                    "tạo mới",
                    $"Điểm: {eventPoint.Points}");
            }
            catch (Exception ex)
            {
                // Notification là best-effort, không làm fail nghiệp vụ chính.
                _logger.LogError(
                    ex,
                    "Không thể tạo thông báo xác nhận tạo cấu hình điểm: EventID={EventId}, EventPointID={EventPointId}, UserID={UserId}",
                    eventPoint.EventID,
                    eventPoint.EventPointID,
                    actorUserId);
            }

            // 5. Trả về DTO
            return new EventPointDto
            {
                EventPointID = eventPoint.EventPointID,
                EventID = eventPoint.EventID,
                RoleType = eventPoint.RoleType,
                Points = eventPoint.Points,
                Description = eventPoint.Description,
                CreatedDate = eventPoint.CreatedDate.HasValue
                            ? DateTimeHelper.ToVietnamTime(eventPoint.CreatedDate.Value)
                            : null
            };
        }

        /// <summary>
        /// Cập nhật cấu hình điểm hiện có
        /// </summary>
        public async Task<EventPointDto> UpdateEventPointAsync(
            int eventPointId,
            UpdateEventPointRequestDto request,
            int actorUserId)
        {
            // 1. Tìm EventPoint hiện có
            var eventPoint = await _context.EventPoints
                .Include(ep => ep.Event)
                .FirstOrDefaultAsync(ep => ep.EventPointID == eventPointId);

            if (eventPoint == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy cấu hình điểm với ID {eventPointId}");
            }

            // 2. Cập nhật các trường
            var previousPoints = eventPoint.Points;
            eventPoint.Points = request.Points;
            eventPoint.Description = request.Description;

            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Đã cập nhật cấu hình điểm sự kiện: EventPointID={EventPointId}, NewPoints={Points}",
                eventPointId, request.Points);

            // Đồng bộ điểm Attendance nếu chỉnh điểm Participant (recalculate)
            if (eventPoint.RoleType == EventRoleTypeEnum.Participant.ToString())
            {
                _attendancePointsSyncQueue.Enqueue(eventPoint.EventID);
            }

            try
            {
                await _notificationService.CreateActorEventPointActionConfirmationAsync(
                    actorUserId,
                    eventPoint.EventID,
                    eventPoint.Event.EventName,
                    eventPoint.RoleType,
                    "cập nhật",
                    $"Điểm: {previousPoints} -> {eventPoint.Points}");
            }
            catch (Exception ex)
            {
                // Notification là best-effort, không làm fail nghiệp vụ chính.
                _logger.LogError(
                    ex,
                    "Không thể tạo thông báo xác nhận cập nhật cấu hình điểm: EventPointID={EventPointId}, EventID={EventId}, UserID={UserId}",
                    eventPoint.EventPointID,
                    eventPoint.EventID,
                    actorUserId);
            }

            // 3. Trả về DTO đã cập nhật
            return new EventPointDto
            {
                EventPointID = eventPoint.EventPointID,
                EventID = eventPoint.EventID,
                RoleType = eventPoint.RoleType,
                Points = eventPoint.Points,
                Description = eventPoint.Description,
                CreatedDate = eventPoint.CreatedDate.HasValue
                                ? DateTimeHelper.ToVietnamTime(eventPoint.CreatedDate.Value)
                                : null
            };
        }

        /// <summary>
        /// Xóa cấu hình điểm
        /// </summary>
        public async Task DeleteEventPointAsync(int eventPointId, int actorUserId)
        {
            // 1. Tìm EventPoint hiện có
            var eventPoint = await _context.EventPoints
                .Include(ep => ep.Event)
                .FirstOrDefaultAsync(ep => ep.EventPointID == eventPointId);

            if (eventPoint == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy cấu hình điểm với ID {eventPointId}");
            }

            // 2. Kiểm tra xem cấu hình này có đang được sử dụng trong ActivityPoints không
            // Điều này đảm bảo tính toàn vẹn dữ liệu - không xóa các quy tắc đã được áp dụng
            var isInUse = await _context.ActivityPoints
                .AnyAsync(ap => ap.EventPointID == eventPointId);

            if (isInUse)
            {
                throw new InvalidOperationException(
                    "Không thể xóa cấu hình điểm này vì nó đang được sử dụng trong các bản ghi điểm hoạt động. " +
                    "Hãy cân nhắc cập nhật giá trị điểm thay vì xóa.");
            }

            // 3. Xóa cấu hình
            _context.EventPoints.Remove(eventPoint);
            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Đã xóa cấu hình điểm sự kiện: EventPointID={EventPointId}, EventID={EventId}, RoleType={RoleType}",
                eventPointId, eventPoint.EventID, eventPoint.RoleType);

            try
            {
                await _notificationService.CreateActorEventPointActionConfirmationAsync(
                    actorUserId,
                    eventPoint.EventID,
                    eventPoint.Event.EventName,
                    eventPoint.RoleType,
                    "xóa",
                    $"Điểm trước khi xóa: {eventPoint.Points}");
            }
            catch (Exception ex)
            {
                // Notification là best-effort, không làm fail nghiệp vụ chính.
                _logger.LogError(
                    ex,
                    "Không thể tạo thông báo xác nhận xóa cấu hình điểm: EventPointID={EventPointId}, EventID={EventId}, UserID={UserId}",
                    eventPoint.EventPointID,
                    eventPoint.EventID,
                    actorUserId);
            }
        }

        /// <summary>
        /// Lấy giá trị điểm cho một sự kiện và loại vai trò cụ thể.
        /// Phương thức này được hệ thống điểm danh sử dụng để tự động trao điểm.
        /// </summary>
        public async Task<int?> GetPointsForRoleAsync(int eventId, string roleType)
        {
            var eventPoint = await _context.EventPoints
                .FirstOrDefaultAsync(ep => ep.EventID == eventId && ep.RoleType == roleType);

            return eventPoint?.Points;
        }
    }
}
