using System.Threading;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using UniYouth.Api.Contracts.DTOs.Events;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services
{
    /// <summary>
    /// Interface định nghĩa các chức năng đăng ký tham gia sự kiện
    /// dành cho người dùng (Đoàn viên / Hội viên)
    /// </summary>
    public interface IEventRegistrationService
    {
        Task<EventRegistrationResultDto> RegisterForEventAsync(int eventId, int userId);
        Task<EventRegistrationResultDto> CancelRegistrationAsync(int eventId, int userId, string? cancellationReason);
        Task<EventRegistrationResultDto?> GetMyRegistrationAsync(int eventId, int userId);
        Task<EventRegistrationListResponseDto> GetEventRegistrationsAsync(
            int eventId,
            int requesterUserId,
            bool isAdmin,
            int? status,
            int pageNumber,
            int pageSize,
            CancellationToken cancellationToken = default);
    }

    /// <summary>
    /// Service xử lý toàn bộ nghiệp vụ liên quan đến đăng ký và hủy đăng ký sự kiện
    /// 
    /// LƯU Ý QUAN TRỌNG:
    /// - Mọi business rule đều được xử lý tại đây
    /// - Controller chỉ đóng vai trò điều phối request/response
    /// - Sử dụng transaction để đảm bảo tính toàn vẹn dữ liệu
    /// </summary>
    public class EventRegistrationService : IEventRegistrationService
    {
        private readonly UniYouthDbContext _context;
        private readonly ILogger<EventRegistrationService> _logger;
        private readonly INotificationService _notificationService;

        public EventRegistrationService(
            UniYouthDbContext context,
            ILogger<EventRegistrationService> logger,
            INotificationService notificationService)
        {
            _context = context;
            _logger = logger;
            _notificationService = notificationService;
        }

        /// <summary>
        /// Lấy danh sách đăng ký tham gia sự kiện (dành cho Web quản lý).
        /// - Admin: xem mọi event
        /// - CanBo: chỉ xem event do mình tạo (CreatedBy)
        /// </summary>
        public async Task<EventRegistrationListResponseDto> GetEventRegistrationsAsync(
            int eventId,
            int requesterUserId,
            bool isAdmin,
            int? status,
            int pageNumber,
            int pageSize,
            CancellationToken cancellationToken = default)
        {
            if (status.HasValue && status is not (0 or 1))
            {
                throw new InvalidOperationException("status không hợp lệ (chỉ nhận 0 hoặc 1)");
            }

            if (pageNumber <= 0)
            {
                pageNumber = 1;
            }

            if (pageSize <= 0)
            {
                pageSize = 20;
            }

            if (pageSize > 100)
            {
                pageSize = 100;
            }

            var eventInfo = await _context.Events
                .AsNoTracking()
                .Where(e => e.EventID == eventId)
                .Select(e => new { e.EventID, e.EventName, e.CreatedBy })
                .FirstOrDefaultAsync(cancellationToken);

            if (eventInfo == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
            }

            if (!isAdmin && eventInfo.CreatedBy != requesterUserId)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền truy cập danh sách đăng ký của sự kiện này");
            }

            var query = _context.EventRegistrations
                .AsNoTracking()
                .Where(r => r.EventID == eventId);

            if (status.HasValue)
            {
                query = query.Where(r => r.Status == (byte)status.Value);
            }

            var total = await query.CountAsync(cancellationToken);

            var items = await query
                .OrderByDescending(r => r.RegisterTime)
                .ThenByDescending(r => r.RegistrationID)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new EventRegistrationItemDto
                {
                    RegistrationId = r.RegistrationID,
                    UserId = r.UserID,
                    Code = r.User.Code,
                    FullName = r.User.FullName,
                    Email = r.User.Email,
                    RegisterTime = r.RegisterTime.HasValue
                        ? DateTimeHelper.ToVietnamTime(r.RegisterTime.Value)
                        : null,
                    Status = r.Status ?? 0,
                    CancellationReason = r.CancellationReason
                })
                .ToListAsync(cancellationToken);

            return new EventRegistrationListResponseDto
            {
                EventId = eventInfo.EventID,
                EventName = eventInfo.EventName,
                Total = total,
                Items = items
            };
        }

        /// <summary>
        /// Đăng ký tham gia sự kiện cho người dùng
        /// 
        /// TRANSACTION – LÝ DO BẮT BUỘC:
        /// - Cần thực hiện đồng thời 2 thao tác:
        ///   (1) Tạo bản ghi đăng ký sự kiện
        ///   (2) Tăng số lượng người tham gia (CurrentParticipants)
        /// - Nếu không dùng transaction, có thể xảy ra tình trạng đăng ký vượt quá số lượng cho phép
        ///   khi nhiều người đăng ký cùng lúc
        /// 
        /// KIỂM SOÁT CONCURRENCY:
        /// - Sử dụng IsolationLevel.Serializable để tránh phantom read
        /// - Ràng buộc UNIQUE(EventID, UserID) ngăn đăng ký trùng
        /// - Khoá bản ghi sự kiện trong suốt transaction
        /// </summary>
        public async Task<EventRegistrationResultDto> RegisterForEventAsync(int eventId, int userId)
        {
            //ExecutionStrategy giúp tự động retry khi gặp lỗi tạm thời(ví dụ: deadlock, timeout)
            var strategy = _context.Database.CreateExecutionStrategy();

            return await strategy.ExecuteAsync(async () =>
            {
                // Bắt đầu transaction với mức cô lập cao nhất để đảm bảo dữ liệu nhất quán
                await using var transaction = await _context.Database.BeginTransactionAsync(
                    System.Data.IsolationLevel.Serializable);

                try
                {
                    // 1. KIỂM TRA SỰ KIỆN TỒN TẠI
                    // Việc truy vấn trong transaction giúp khoá bản ghi sự kiện
                    var eventEntity = await _context.Events
                        .Where(e => e.EventID == eventId)
                        .FirstOrDefaultAsync();

                    if (eventEntity == null)
                    {
                        throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
                    }

                    // 2. KIỂM TRA TRẠNG THÁI SỰ KIỆN
                    // Chỉ cho phép đăng ký khi sự kiện đang ở trạng thái Mở đăng ký
                    if (eventEntity.Status != 1) // 0: Draft, 1: Open, 2: Ongoing, 3: Closed, 4: Cancelled
                    {
                        throw new InvalidOperationException("Sự kiện hiện chưa mở đăng ký");
                    }

                    // 3. KIỂM TRA HẠN CUỐI ĐĂNG KÝ
                    if (eventEntity.RegistrationDeadline.HasValue
                        && DateTime.Now > eventEntity.RegistrationDeadline.Value)
                    {
                        throw new InvalidOperationException("Đã hết hạn đăng ký sự kiện");
                    }

                    var now = DateTime.Now;

                    // 4. KIỂM TRA NGƯỜI DÙNG ĐÃ ĐĂNG KÝ CHƯA (CHỈ TÍNH ĐĂNG KÝ ĐANG HIỆU LỰC)
                    // Kiểm tra này nhằm trả về thông báo thân thiện cho người dùng
                    // Ràng buộc UNIQUE trong DB vẫn là lớp bảo vệ cuối cùng
                    var existingRegistration = await _context.EventRegistrations
                        .Where(er => er.EventID == eventId && er.UserID == userId && er.Status == 0)
                        .FirstOrDefaultAsync();

                    if (existingRegistration != null)
                    {
                        throw new InvalidOperationException("Bạn đã đăng ký tham gia sự kiện này");
                    }

                    // 4.1. TÌM BẢN GHI ĐÃ HỦY ĐỂ KÍCH HOẠT LẠI NẾU NGƯỜI DÙNG ĐĂNG KÝ LẠI
                    // DB đang có UNIQUE(EventID, UserID), nên khi đã từng hủy thì phải dùng lại bản ghi cũ
                    // thay vì insert bản ghi mới.
                    var cancelledRegistration = await _context.EventRegistrations
                        .Where(er => er.EventID == eventId && er.UserID == userId && er.Status == 1)
                        .OrderByDescending(er => er.UpdatedDate ?? er.RegisterTime ?? er.CreatedDate)
                        .FirstOrDefaultAsync();

                    // 5. KIỂM TRA TRÙNG THỜI GIAN VỚI CÁC SỰ KIỆN KHÁC ĐÃ ĐĂNG KÝ
                    // Chỉ xét các đăng ký còn hiệu lực (Status = 0) và event khác event hiện tại.
                    // Nếu event kia đã ở trạng thái Closed/Cancelled thì KHÔNG chặn đăng ký,
                    // kể cả khi EndTime trên dữ liệu vẫn còn trong tương lai.
                    // Quy tắc overlap:
                    // - existing.StartTime < new.EndTime
                    // - existing.EndTime > new.StartTime
                    // Nếu 2 sự kiện chỉ chạm mốc thời gian (event A kết thúc đúng lúc event B bắt đầu)
                    // thì KHÔNG coi là trùng.
                    var overlappingRegistration = await _context.EventRegistrations
                        .AsNoTracking()
                        .Where(er => er.UserID == userId
                            && er.EventID != eventId
                            && er.Status == 0
                            && (er.Event.Status == 1 || er.Event.Status == 2)
                            && er.Event.StartTime < eventEntity.EndTime
                            && er.Event.EndTime > eventEntity.StartTime)
                        .Select(er => new
                        {
                            er.EventID,
                            er.Event.EventName,
                            er.Event.StartTime,
                            er.Event.EndTime
                        })
                        .OrderBy(er => er.StartTime)
                        .FirstOrDefaultAsync();

                    if (overlappingRegistration != null)
                    {
                        throw new InvalidOperationException(
                            $"Bạn đã đăng ký sự kiện \"{overlappingRegistration.EventName}\" bị trùng thời gian với sự kiện này");
                    }

                    // 6. KIỂM TRA SỐ LƯỢNG THAM GIA (ĐOẠN NGHIỆP VỤ QUAN TRỌNG)
                    // Defensive: một số DB có thể để CurrentParticipants = NULL (do seed/legacy).
                    // Chuẩn hoá về 0 để tránh logic sai và đảm bảo phép tăng luôn ra số.
                    eventEntity.CurrentParticipants ??= 0;

                    if (eventEntity.MaxParticipants.HasValue
                        && eventEntity.CurrentParticipants >= eventEntity.MaxParticipants.Value)
                    {
                        throw new InvalidOperationException("Sự kiện đã đủ số lượng người tham gia");
                    }

                    // 7. TẠO BẢN GHI ĐĂNG KÝ SỰ KIỆN
                    EventRegistration registration;

                    if (cancelledRegistration != null)
                    {
                        registration = cancelledRegistration;
                        registration.RegisterTime = now;
                        registration.Status = 0;
                        registration.CancellationReason = null;
                        registration.UpdatedDate = now;

                        _context.EventRegistrations.Update(registration);
                    }
                    else
                    {
                        registration = new EventRegistration
                        {
                            EventID = eventId,
                            UserID = userId,
                            RegisterTime = now,
                            Status = 0, // 0: Đang đăng ký
                            CancellationReason = null,
                            CreatedDate = now,
                            UpdatedDate = now
                        };

                        _context.EventRegistrations.Add(registration);
                    }

                    // 8. TĂNG SỐ LƯỢNG NGƯỜI THAM GIA
                    // BẮT BUỘC thực hiện cùng transaction với việc tạo đăng ký
                    eventEntity.CurrentParticipants += 1;
                    eventEntity.UpdatedDate = now;
                    _context.Events.Update(eventEntity);

                    // 9. LƯU TOÀN BỘ THAY ĐỔI MỘT CÁCH NGUYÊN TỬ
                    await _context.SaveChangesAsync();

                    // 10. COMMIT TRANSACTION
                    // Chỉ commit nếu tất cả các thao tác thành công
                    await transaction.CommitAsync();

                    _logger.LogInformation(
                        "Người dùng {UserId} đã đăng ký thành công sự kiện {EventId}. " +
                        "Số người tham gia hiện tại: {CurrentParticipants}/{MaxParticipants}",
                        userId, eventId, eventEntity.CurrentParticipants, eventEntity.MaxParticipants);

                    // ================= NOTIFICATION =================
                    try
                    {
                        await _notificationService.CreateEventRegistrationNotificationAsync(
                            userId,
                            eventEntity.EventID,
                            eventEntity.EventName
                        );
                    }
                    catch (Exception ex)
                    {
                        // Notification không được làm fail đăng ký
                        _logger.LogError(ex,
                            "Không thể tạo thông báo đăng ký sự kiện: User {UserId}, Event {EventId}",
                            userId, eventId);
                    }

                    // Alert vận hành cho Web quản trị khi sự kiện đã đạt đủ số lượng
                    if (eventEntity.MaxParticipants.HasValue
                        && eventEntity.CurrentParticipants == eventEntity.MaxParticipants.Value)
                    {
                        try
                        {
                            await _notificationService.CreateEventCapacityFullAlertAsync(
                                eventEntity.EventID,
                                eventEntity.EventName,
                                eventEntity.CurrentParticipants.Value,
                                eventEntity.MaxParticipants.Value);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex,
                                "Không thể tạo alert event full: Event {EventId}",
                                eventId);
                        }
                    }

                    // 11. TRẢ VỀ THÔNG TIN ĐĂNG KÝ ĐẦY ĐỦ
                    var user = await _context.Users.FindAsync(userId);

                    return new EventRegistrationResultDto
                    {
                        RegistrationID = registration.RegistrationID,
                        EventID = eventEntity.EventID,
                        EventName = eventEntity.EventName,
                        UserID = userId,
                        UserFullName = user?.FullName ?? "Không xác định",
                        RegisterTime = registration.RegisterTime,
                        Status = "Đã đăng ký",
                        CancellationReason = null,
                        CreatedDate = registration.CreatedDate.HasValue
                                    ? DateTimeHelper.ToVietnamTime(registration.CreatedDate.Value)
                                    : null
                    };
                }
                catch (DbUpdateException ex) when (ex.InnerException?.Message.Contains("IX_EventRegistrations") == true
                                                || ex.InnerException?.Message.Contains("UNIQUE") == true)
                {
                    // Trường hợp xảy ra đăng ký trùng do nhiều request đồng thời
                    await transaction.RollbackAsync();
                    _logger.LogWarning(ex, "Phát hiện đăng ký trùng lặp - User {UserId} Event {EventId}", userId, eventId);
                    throw new InvalidOperationException("Bạn đã đăng ký tham gia sự kiện này");
                }
                catch (Exception ex)
                {
                    // Rollback transaction khi xảy ra bất kỳ lỗi nào
                    await transaction.RollbackAsync();
                    _logger.LogError(ex, "Lỗi khi đăng ký sự kiện - UserId: {UserId}, EventId: {EventId}", userId, eventId);
                    throw;
                }
            });
        }

        /// <summary>
        /// Hủy đăng ký tham gia sự kiện của người dùng
        /// 
        /// TRANSACTION:
        /// - Cập nhật trạng thái đăng ký
        /// - Giảm số lượng người tham gia
        /// - Đảm bảo dữ liệu luôn nhất quán
        /// </summary>
        public async Task<EventRegistrationResultDto> CancelRegistrationAsync(
            int eventId,
            int userId,
            string? cancellationReason)
        {
            var strategy = _context.Database.CreateExecutionStrategy();

            return await strategy.ExecuteAsync(async () =>
            {
                await using var transaction = await _context.Database.BeginTransactionAsync(
                            System.Data.IsolationLevel.Serializable);

                try
                {
                    // 1. KIỂM TRA SỰ KIỆN
                    var eventEntity = await _context.Events
                        .Where(e => e.EventID == eventId)
                        .FirstOrDefaultAsync();

                    if (eventEntity == null)
                    {
                        throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
                    }

                    // 2. KHÔNG CHO PHÉP HỦY VỚI SỰ KIỆN ĐÃ KẾT THÚC HOẶC BỊ HỦY
                    if (eventEntity.Status == 3 || eventEntity.Status == 4) // 3: Closed, 4: Cancelled
                    {
                        throw new InvalidOperationException("Không thể hủy đăng ký sự kiện đã kết thúc hoặc bị hủy");
                    }

                    // 3. TÌM ĐĂNG KÝ ĐANG HIỆU LỰC
                    var registration = await _context.EventRegistrations
                        .Where(er => er.EventID == eventId && er.UserID == userId && er.Status == 0)
                        .FirstOrDefaultAsync();

                    if (registration == null)
                    {
                        throw new KeyNotFoundException("Bạn chưa đăng ký tham gia sự kiện này");
                    }

                    // 4. KIỂM TRA XEM ĐÃ HỦY CHƯA
                    if (registration.Status == 1)
                    {
                        throw new InvalidOperationException("Đăng ký đã bị hủy trước đó");
                    }

                    // 5. CẬP NHẬT TRẠNG THÁI ĐĂNG KÝ
                    registration.Status = 1; // 1: Cancelled
                    registration.CancellationReason = cancellationReason;
                    registration.UpdatedDate = DateTime.Now;
                    _context.EventRegistrations.Update(registration);

                    // 6. GIẢM SỐ LƯỢNG NGƯỜI THAM GIA
                    // Must be in same transaction as status update
                    if (eventEntity.CurrentParticipants > 0)
                    {
                        eventEntity.CurrentParticipants -= 1;
                        eventEntity.UpdatedDate = DateTime.Now;
                        _context.Events.Update(eventEntity);
                    }

                    // 7. LƯU DỮ LIỆU
                    await _context.SaveChangesAsync();

                    // 8. COMMIT TRANSACTION
                    await transaction.CommitAsync();

                    _logger.LogInformation(
                        "Người dùng {UserId} đã hủy đăng ký sự kiện {EventId}. " +
                        "Lý do: {Reason}. Số người tham gia hiện tại: {CurrentParticipants}",
                        userId, eventId, cancellationReason ?? "Không có", eventEntity.CurrentParticipants);

                    // ================= NOTIFICATION =================
                    try
                    {
                        await _notificationService.CreateEventCancelRegistrationNotificationAsync(
                            userId,
                            eventEntity.EventID,
                            eventEntity.EventName,
                            cancellationReason
                        );
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex,
                            "Không thể tạo thông báo hủy đăng ký: User {UserId}, Event {EventId}",
                            userId, eventId);
                    }

                    // 9. FETCH COMPLETE DATA FOR RESPONSE
                    var user = await _context.Users.FindAsync(userId);

                    return new EventRegistrationResultDto
                    {
                        RegistrationID = registration.RegistrationID,
                        EventID = eventEntity.EventID,
                        EventName = eventEntity.EventName,
                        UserID = userId,
                        UserFullName = user?.FullName ?? "Không xác định",
                        RegisterTime = registration.RegisterTime,
                        Status = "Đã hủy",
                        CancellationReason = registration.CancellationReason,
                        CreatedDate = registration.CreatedDate.HasValue
                                    ? DateTimeHelper.ToVietnamTime(registration.CreatedDate.Value)
                                    : null
                    };
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    _logger.LogError(ex, "Lỗi khi hủy đăng ký sự kiện - User {UserId} Event {EventId}", userId, eventId);
                    throw;
                }
            });
        }

        /// <summary>
        /// Lấy thông tin đăng ký sự kiện của người dùng hiện tại
        /// </summary>
        public async Task<EventRegistrationResultDto?> GetMyRegistrationAsync(int eventId, int userId)
        {
            return await _context.EventRegistrations
                .AsNoTracking()
                .Where(r => r.EventID == eventId && r.UserID == userId)
                .Select(r => new EventRegistrationResultDto
                {
                    RegistrationID = r.RegistrationID,
                    EventID = r.EventID,
                    EventName = r.Event.EventName,
                    UserID = r.UserID,
                    UserFullName = r.User.FullName,
                    RegisterTime = r.RegisterTime,
                    Status = r.Status == 0 ? "Đã đăng ký" : "Đã hủy",
                    CancellationReason = r.CancellationReason,
                    CreatedDate = r.CreatedDate.HasValue
                                ? DateTimeHelper.ToVietnamTime(r.CreatedDate.Value)
                                : null
                })
                .FirstOrDefaultAsync();
        }

    }
}

