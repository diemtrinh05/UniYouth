using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services
{
    /// <summary>
    /// Interface định nghĩa các chức năng quản lý sự kiện
    /// </summary>
    public interface IEventService
    {
        Task<PaginatedResultDto<EventListItemDto>> GetEventsAsync(
            int pageNumber,
            int pageSize,
            int? status = null,
            int? eventTypeId = null,
            int? instituteId = null,
            string? q = null,
            string? sortBy = null,
            string? sortDir = null,
            DateTime? startDate = null,
            DateTime? endDate = null);
        Task<PaginatedResultDto<EventListItemDto>> GetEventsForAdminAsync(
        int pageNumber,
        int pageSize,
        int? status = null,
        string? q = null,
        int? eventTypeId = null,
        DateTime? startFrom = null,
        DateTime? startTo = null,
        string? sortBy = null,
        string? sortDir = null,
        int? unitId = null,
        int? instituteId = null);

        Task<EventDetailDto?> GetEventByIdAsync(int eventId);
        Task<EventDetailDto> CreateEventAsync(CreateEventRequestDto request, int createdBy, int? unitId = null, int? instituteId = null);
        Task<EventDetailDto?> UpdateEventAsync(int eventId, UpdateEventRequestDto request, int? unitId = null, int? instituteId = null, int? actorUserId = null);
        Task<EventDetailDto> CloseEventAsync(int eventId, int? unitId = null, int? instituteId = null, int? actorUserId = null);
        Task<EventDetailDto> CancelEventAsync(int eventId, string? reason, int? unitId = null, int? instituteId = null, int? actorUserId = null);
    }

    /// <summary>
    /// Service xử lý các nghiệp vụ liên quan đến sự kiện
    /// </summary>
    public class EventService : IEventService
    {
        private readonly UniYouthDbContext _context;
        private readonly ILogger<EventService> _logger;
        private readonly INotificationService _notificationService;
        private readonly IPublicUrlBuilder _publicUrlBuilder;
        public EventService(
            UniYouthDbContext context,
            ILogger<EventService> logger,
            INotificationService notificationService,
            IPublicUrlBuilder publicUrlBuilder)
        {
            _context = context;
            _logger = logger;
            _notificationService = notificationService;
            _publicUrlBuilder = publicUrlBuilder;
        }

        /// <summary>
        /// Lấy danh sách sự kiện có phân trang
        /// Dành cho Mobile App: chỉ hiển thị các sự kiện đang mở, đang diễn ra hoặc đã kết thúc
        /// Hỗ trợ lọc theo loại sự kiện, viện và khoảng thời gian
        /// </summary>
        public async Task<PaginatedResultDto<EventListItemDto>> GetEventsAsync(
            int pageNumber,
            int pageSize,
            int? status = null,
            int? eventTypeId = null,
            int? instituteId = null,
            string? q = null,
            string? sortBy = null,
            string? sortDir = null,
            DateTime? startDate = null,
            DateTime? endDate = null)
        {
            try
            {
                _logger.LogInformation("Lấy danh sách sự kiện - Trang: {Page}, Kích thước trang: {Size}", pageNumber, pageSize);

                if (status.HasValue &&
                    status.Value != (int)EventStatus.Open &&
                    status.Value != (int)EventStatus.Ongoing &&
                    status.Value != (int)EventStatus.Closed)
                {
                    throw new InvalidOperationException("Status chỉ hỗ trợ Open, Ongoing hoặc Closed");
                }

                // Truy vấn cơ bản
                // MOBILE APP:
                // - nếu không truyền status: chỉ hiển thị Open, Ongoing, Closed
                // - nếu có truyền status: lọc đúng trạng thái được yêu cầu
                var query = _context.Set<Event>()
                    .AsNoTracking()
                    .AsQueryable();

                if (status.HasValue)
                {
                    query = query.Where(e => e.Status == status.Value);
                }
                else
                {
                    query = query.Where(e =>
                        e.Status == (byte)EventStatus.Open ||
                        e.Status == (byte)EventStatus.Ongoing ||
                        e.Status == (byte)EventStatus.Closed);
                }

                // Lọc theo loại sự kiện
                if (eventTypeId.HasValue)
                {
                    query = query.Where(e => e.EventTypeID == eventTypeId.Value);
                }

                // Lọc theo viện
                if (instituteId.HasValue)
                {
                    query = query.Where(e => e.InstituteID == instituteId.Value);
                }

                // Lọc theo thời gian bắt đầu
                if (startDate.HasValue)
                {
                    //query = query.Where(e => e.StartTime >= startDate.Value);
                    var startUtc = DateTimeHelper.FromVietnamTimeToUtc(startDate.Value);
                    query = query.Where(e => e.StartTime >= startUtc);
                }

                if (endDate.HasValue)
                {
                    //query = query.Where(e => e.StartTime <= endDate.Value);
                    var endUtc = DateTimeHelper.FromVietnamTimeToUtc(endDate.Value);
                    query = query.Where(e => e.StartTime <= endUtc);
                }

                q = string.IsNullOrWhiteSpace(q) ? null : q.Trim();
                if (q != null)
                {
                    query = query.Where(e =>
                        e.EventName.Contains(q) ||
                        (e.LocationName != null && e.LocationName.Contains(q)));
                }

                // Tổng số bản ghi trước khi phân trang
                var totalCount = await query.CountAsync();

                sortBy = string.IsNullOrWhiteSpace(sortBy) ? "startTime" : sortBy.Trim();
                sortDir = string.IsNullOrWhiteSpace(sortDir) ? "asc" : sortDir.Trim();
                var isDesc = sortDir.Equals("desc", StringComparison.OrdinalIgnoreCase);

                // Mobile: mặc định sắp xếp theo StartTime tăng dần (sự kiện sắp diễn ra lên trước)
                IOrderedQueryable<Event> orderedQuery;
                switch (sortBy.ToLowerInvariant())
                {
                    case "eventname":
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.EventName).ThenByDescending(e => e.EventID)
                            : query.OrderBy(e => e.EventName).ThenBy(e => e.EventID);
                        break;

                    case "createddate":
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.CreatedDate).ThenByDescending(e => e.EventID)
                            : query.OrderBy(e => e.CreatedDate).ThenBy(e => e.EventID);
                        break;

                    case "eventid":
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.EventID)
                            : query.OrderBy(e => e.EventID);
                        break;

                    case "starttime":
                    default:
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.StartTime).ThenByDescending(e => e.EventID)
                            : query.OrderBy(e => e.StartTime).ThenBy(e => e.EventID);
                        break;
                }

                var events = await orderedQuery
                    .Skip((pageNumber - 1) * pageSize)
                    .Take(pageSize)
                    .Select(e => new
                    {
                        e.EventID,
                        e.EventName,
                        e.Description,
                        e.StartTime,
                        e.EndTime,
                        e.LocationName,
                        e.MaxParticipants,
                        e.CurrentParticipants,
                        e.Status,
                        e.RegistrationDeadline,
                        e.EnableFaceVerification,
                        EventTypeName = e.EventType.TypeName,
                        InstituteName = e.Institute != null ? e.Institute.InstituteName : null,
                        ThumbnailImageUrl = e.EventImages
                            .Where(img => img.ImageType == "Thumbnail" || img.ImageType == "Banner")
                            .OrderByDescending(img => img.ImageType == "Thumbnail")
                            .ThenBy(img => img.DisplayOrder ?? int.MaxValue)
                            .Select(img => img.ImageUrl)
                            .FirstOrDefault()
                    })
                    .ToListAsync();

                // Map sang DTO
                var items = events.Select(e => new EventListItemDto
                {
                    EventId = e.EventID,
                    EventName = e.EventName,
                    Description = e.Description,
                    StartTime = DateTimeHelper.ToVietnamTime(e.StartTime),
                    EndTime = DateTimeHelper.ToVietnamTime(e.EndTime),
                    LocationName = e.LocationName,
                    MaxParticipants = e.MaxParticipants,
                    CurrentParticipants = e.CurrentParticipants,
                    Status = (EventStatus)e.Status!,
                    StatusName = ((EventStatus)e.Status).ToDisplayName(),
                    EventTypeName = e.EventTypeName,
                    InstituteName = e.InstituteName,
                    RegistrationDeadline = e.RegistrationDeadline.HasValue
                        ? DateTimeHelper.ToVietnamTime(e.RegistrationDeadline.Value)
                        : null,
                    EnableFaceVerification = e.EnableFaceVerification,
                    ThumbnailUrl = BuildFullUrl(e.ThumbnailImageUrl),
                    HasAvailableSlots = !e.MaxParticipants.HasValue ||
                                        e.CurrentParticipants < e.MaxParticipants.Value
                }).ToList();

                return new PaginatedResultDto<EventListItemDto>
                {
                    Items = items,
                    TotalCount = totalCount,
                    PageNumber = pageNumber,
                    PageSize = pageSize
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách sự kiện");
                throw;
            }
        }

        public async Task<PaginatedResultDto<EventListItemDto>> GetEventsForAdminAsync(
            int pageNumber,
            int pageSize,
            int? status = null,
            string? q = null,
            int? eventTypeId = null,
            DateTime? startFrom = null,
            DateTime? startTo = null,
            string? sortBy = null,
            string? sortDir = null,
            int? unitId = null,
            int? instituteId = null)
        {
            try
            {
                _logger.LogInformation("Admin lấy danh sách sự kiện - Trang {Page}, Size {Size}", pageNumber, pageSize);

                var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);

                var query = _context.Set<Event>()
                    .AsNoTracking()
                    .AsQueryable();

                // Lọc theo trạng thái nếu có
                if (status.HasValue)
                {
                    query = query.Where(e => e.Status == status.Value);
                }

                q = string.IsNullOrWhiteSpace(q) ? null : q.Trim();
                if (q != null)
                {
                    query = query.Where(e =>
                        e.EventName.Contains(q) ||
                        (e.LocationName != null && e.LocationName.Contains(q)));
                }

                if (eventTypeId.HasValue)
                {
                    query = query.Where(e => e.EventTypeID == eventTypeId.Value);
                }

                if (startFrom.HasValue)
                {
                    var fromUtc = DateTimeHelper.FromVietnamTimeToUtc(startFrom.Value);
                    query = query.Where(e => e.StartTime >= fromUtc);
                }

                if (startTo.HasValue)
                {
                    var toUtc = DateTimeHelper.FromVietnamTimeToUtc(startTo.Value);
                    query = query.Where(e => e.StartTime <= toUtc);
                }

                // Data-level authorization cho CanBo: chỉ xem event thuộc viện được phép
                if (scopeInstituteId.HasValue)
                {
                    query = query.Where(e => e.InstituteID == scopeInstituteId.Value);
                }

                var totalCount = await query.CountAsync();

                sortBy = string.IsNullOrWhiteSpace(sortBy) ? "eventId" : sortBy.Trim();
                sortDir = string.IsNullOrWhiteSpace(sortDir) ? "desc" : sortDir.Trim();
                var isDesc = sortDir.Equals("desc", StringComparison.OrdinalIgnoreCase);

                // Admin: mới nhất lên đầu + phân trang
                IOrderedQueryable<Event> orderedQuery;
                switch (sortBy.ToLowerInvariant())
                {
                    case "starttime":
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.StartTime).ThenByDescending(e => e.EventID)
                            : query.OrderBy(e => e.StartTime).ThenBy(e => e.EventID);
                        break;

                    case "createddate":
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.CreatedDate).ThenByDescending(e => e.EventID)
                            : query.OrderBy(e => e.CreatedDate).ThenBy(e => e.EventID);
                        break;

                    case "status":
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.Status).ThenByDescending(e => e.EventID)
                            : query.OrderBy(e => e.Status).ThenBy(e => e.EventID);
                        break;

                    case "eventname":
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.EventName).ThenByDescending(e => e.EventID)
                            : query.OrderBy(e => e.EventName).ThenBy(e => e.EventID);
                        break;

                    case "eventid":
                    default:
                        orderedQuery = isDesc
                            ? query.OrderByDescending(e => e.EventID)
                            : query.OrderBy(e => e.EventID);
                        break;
                }

                var events = await orderedQuery
                    .Skip((pageNumber - 1) * pageSize)
                    .Take(pageSize)
                    .Select(e => new
                    {
                        e.EventID,
                        e.EventName,
                        e.Description,
                        e.StartTime,
                        e.EndTime,
                        e.LocationName,
                        e.MaxParticipants,
                        e.CurrentParticipants,
                        e.Status,
                        e.RegistrationDeadline,
                        e.EnableFaceVerification,
                        EventTypeName = e.EventType.TypeName,
                        InstituteName = e.Institute != null ? e.Institute.InstituteName : null,
                        ThumbnailImageUrl = e.EventImages
                            .Where(img => img.ImageType == "Thumbnail" || img.ImageType == "Banner")
                            .OrderByDescending(img => img.ImageType == "Thumbnail")
                            .ThenBy(img => img.DisplayOrder ?? int.MaxValue)
                            .Select(img => img.ImageUrl)
                            .FirstOrDefault()
                    })
                    .ToListAsync();

                var items = events.Select(e => new EventListItemDto
                {
                    EventId = e.EventID,
                    EventName = e.EventName,
                    Description = e.Description,
                    StartTime = DateTimeHelper.ToVietnamTime(e.StartTime),
                    EndTime = DateTimeHelper.ToVietnamTime(e.EndTime),
                    LocationName = e.LocationName,
                    MaxParticipants = e.MaxParticipants,
                    CurrentParticipants = e.CurrentParticipants,
                    Status = (EventStatus)e.Status!,
                    StatusName = ((EventStatus)e.Status).ToDisplayName(),
                    EventTypeName = e.EventTypeName,
                    InstituteName = e.InstituteName,
                    RegistrationDeadline = e.RegistrationDeadline.HasValue
                        ? DateTimeHelper.ToVietnamTime(e.RegistrationDeadline.Value)
                        : null,
                    EnableFaceVerification = e.EnableFaceVerification,
                    ThumbnailUrl = BuildFullUrl(e.ThumbnailImageUrl),
                    HasAvailableSlots = !e.MaxParticipants.HasValue ||
                                        e.CurrentParticipants < e.MaxParticipants.Value
                }).ToList();

                return new PaginatedResultDto<EventListItemDto>
                {
                    Items = items,
                    TotalCount = totalCount,
                    PageNumber = pageNumber,
                    PageSize = pageSize
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi admin lấy danh sách sự kiện");
                throw;
            }
        }


        /// <summary>
        /// Lấy chi tiết sự kiện theo ID
        /// Trả về đầy đủ thông tin sự kiện bao gồm hình ảnh và vị trí
        /// </summary>
        public async Task<EventDetailDto?> GetEventByIdAsync(int eventId)
        {
            try
            {
                _logger.LogInformation("Lấy chi tiết sự kiện với EventId: {EventId}", eventId);

                var eventEntity = await _context.Set<Event>()
                    .Include(e => e.EventType)
                    .Include(e => e.Institute)
                    .Include(e => e.EventImages.OrderBy(img => img.DisplayOrder))
                    .Include(e => e.CreatedByNavigation)
                    .FirstOrDefaultAsync(e => e.EventID == eventId);

                if (eventEntity == null)
                {
                    _logger.LogWarning("Không tìm thấy sự kiện với EventId: {EventId}", eventId);
                    return null;
                }

                // Map sang DTO
                var dto = new EventDetailDto
                {
                    EventId = eventEntity.EventID,
                    EventName = eventEntity.EventName,
                    Description = eventEntity.Description,
                    StartTime = DateTimeHelper.ToVietnamTime(eventEntity.StartTime),
                    EndTime = DateTimeHelper.ToVietnamTime(eventEntity.EndTime),
                    LocationName = eventEntity.LocationName,
                    Latitude = eventEntity.Latitude,
                    Longitude = eventEntity.Longitude,
                    AllowRadius = eventEntity.AllowRadius,
                    MaxParticipants = eventEntity.MaxParticipants,
                    CurrentParticipants = eventEntity.CurrentParticipants,
                    Status = (EventStatus)eventEntity.Status!,
                    StatusName = ((EventStatus)eventEntity.Status).ToDisplayName(),
                    EventType = new EventTypeInfoDto
                    {
                        TypeId = eventEntity.EventType.TypeID,
                        TypeName = eventEntity.EventType.TypeName,
                        Description = eventEntity.EventType.Description
                    },
                    Institute = eventEntity.Institute != null ? new InstituteInfoDto
                    {
                        InstituteId = eventEntity.Institute.InstituteID,
                        InstituteName = eventEntity.Institute.InstituteName
                    } : null,
                    RegistrationDeadline = eventEntity.RegistrationDeadline.HasValue
                                    ? DateTimeHelper.ToVietnamTime(eventEntity.RegistrationDeadline.Value)
                                    : null,
                    EnableFaceVerification = eventEntity.EnableFaceVerification,
                    Images = eventEntity.EventImages.Select(img => new EventImageDto
                    {
                        ImageId = img.ImageID,
                        ImageUrl = BuildFullUrl(img.ImageUrl),
                        ImageType = img.ImageType,
                        Caption = img.Caption,
                        DisplayOrder = img.DisplayOrder
                    }).ToList(),
                    CreatedByName = eventEntity.CreatedByNavigation.FullName,
                    CreatedDate = DateTimeHelper.ToVietnamTime(eventEntity.CreatedDate!.Value),
                    HasAvailableSlots = !eventEntity.MaxParticipants.HasValue ||
                                       (eventEntity.CurrentParticipants ?? 0) < eventEntity.MaxParticipants.Value,
                    IsRegistrationClosed = eventEntity.RegistrationDeadline.HasValue &&
                                          DateTime.Now > eventEntity.RegistrationDeadline.Value
                };

                return dto;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy chi tiết sự kiện với EventId: {EventId}", eventId);
                throw;
            }
        }

        /// <summary>
        /// Tạo mới sự kiện
        /// Chỉ Cán bộ và Admin được phép thực hiện
        /// </summary>
        public async Task<EventDetailDto> CreateEventAsync(CreateEventRequestDto request, int createdBy, int? unitId = null, int? instituteId = null)
        {
            try
            {
                _logger.LogInformation("Tạo mới sự kiện: {EventName} bởi UserId: {UserId}",
                    request.EventName, createdBy);

                var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);
                if (scopeInstituteId.HasValue)
                {
                    if (!request.InstituteId.HasValue || request.InstituteId.Value != scopeInstituteId.Value)
                    {
                        throw new UnauthorizedAccessException("Bạn không có quyền tạo sự kiện cho viện này");
                    }
                }

                // Kiểm tra các ràng buộc nghiệp vụ
                ValidateEventDates(request.StartTime, request.EndTime, request.RegistrationDeadline);

                // Kiểm tra loại sự kiện tồn tại
                var eventTypeExists = await _context.Set<EventType>()
                    .AnyAsync(et => et.TypeID == request.EventTypeId);

                if (!eventTypeExists)
                {
                    throw new InvalidOperationException("Loại sự kiện không tồn tại");
                }

                // Kiểm tra viện tồn tại (nếu có)
                if (request.InstituteId.HasValue)
                {
                    var instituteExists = await _context.Set<Institute>()
                        .AnyAsync(i => i.InstituteID == request.InstituteId.Value);

                    if (!instituteExists)
                    {
                        throw new InvalidOperationException("Viện không tồn tại");
                    }
                }

                // Create event entity
                var eventEntity = new Event
                {
                    EventName = request.EventName,
                    Description = request.Description,
                    StartTime = DateTimeHelper.FromVietnamTimeToUtc(request.StartTime),
                    EndTime = DateTimeHelper.FromVietnamTimeToUtc(request.EndTime),
                    LocationName = request.LocationName,
                    Latitude = request.Latitude,
                    Longitude = request.Longitude,
                    AllowRadius = request.AllowRadius,
                    MaxParticipants = request.MaxParticipants,
                    EventTypeID = request.EventTypeId,
                    InstituteID = request.InstituteId,
                    RegistrationDeadline = request.RegistrationDeadline.HasValue
                                    ? DateTimeHelper.FromVietnamTimeToUtc(request.RegistrationDeadline.Value)
                                    : null,
                    EnableFaceVerification = request.EnableFaceVerification,
                    Status = (byte)request.Status,
                    CreatedBy = createdBy, // Set from JWT UserId
                    CurrentParticipants = 0,
                    CreatedDate = DateTime.Now,
                    UpdatedDate = DateTime.Now
                };

                _context.Set<Event>().Add(eventEntity);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Tạo sự kiện thành công với EventId: {EventId}", eventEntity.EventID);

                try
                {
                    await _notificationService.CreateActorEventActionConfirmationAsync(
                        createdBy,
                        eventEntity.EventID,
                        eventEntity.EventName,
                        "tạo mới",
                        null,
                        eventEntity.CreatedDate?.Ticks);
                }
                catch (Exception ex)
                {
                    _logger.LogError(
                        ex,
                        "Không thể tạo thông báo xác nhận thao tác tạo sự kiện cho actor: EventId {EventId}, ActorUserId {UserId}",
                        eventEntity.EventID,
                        createdBy);
                }

                // Return created event detail
                return await GetEventByIdAsync(eventEntity.EventID)
                    ?? throw new InvalidOperationException("Không thể lấy lại thông tin sự kiện vừa tạo");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating event");
                throw;
            }
        }

        /// <summary>
        /// Cập nhật thông tin sự kiện
        /// Chỉ Cán bộ và Admin được phép thực hiện
        /// </summary>
        public async Task<EventDetailDto?> UpdateEventAsync(int eventId, UpdateEventRequestDto request, int? unitId = null, int? instituteId = null, int? actorUserId = null)
        {
            try
            {
                _logger.LogInformation("Cập nhật sự kiện với EventId: {EventId}", eventId);

                var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);

                // Kiểm tra các ràng buộc nghiệp vụ
                ValidateEventDates(request.StartTime, request.EndTime, request.RegistrationDeadline);

                // Find event
                var eventEntity = await _context.Set<Event>()
                    .FirstOrDefaultAsync(e => e.EventID == eventId);

                if (eventEntity == null)
                {
                    _logger.LogWarning("Không tìm thấy sự kiện để cập nhật với EventId: {EventId}", eventId);
                    return null;
                }

                if (scopeInstituteId.HasValue)
                {
                    if (eventEntity.InstituteID != scopeInstituteId.Value)
                    {
                        throw new UnauthorizedAccessException("Bạn không có quyền cập nhật sự kiện của viện này");
                    }

                    // Không cho phép CanBo chuyển event sang viện khác hoặc sang null
                    if (!request.InstituteId.HasValue || request.InstituteId.Value != scopeInstituteId.Value)
                    {
                        throw new UnauthorizedAccessException("Bạn không có quyền thay đổi viện của sự kiện");
                    }
                }

                // Kiểm tra loại sự kiện tồn tại
                var eventTypeExists = await _context.Set<EventType>()
                    .AnyAsync(et => et.TypeID == request.EventTypeId);

                if (!eventTypeExists)
                {
                    throw new InvalidOperationException("Loại sự kiện không tồn tại");
                }

                // Kiểm tra viện tồn tại (nếu có)
                if (request.InstituteId.HasValue)
                {
                    var instituteExists = await _context.Set<Institute>()
                        .AnyAsync(i => i.InstituteID == request.InstituteId.Value);

                    if (!instituteExists)
                    {
                        throw new InvalidOperationException("Viện không tồn tại");
                    }
                }

                //Lưu thông tin cũ
                var oldStartTime = eventEntity.StartTime;
                var oldEndTime = eventEntity.EndTime;
                var oldLocation = eventEntity.LocationName;
                var oldStatus = eventEntity.Status;

                var currentStatus = (EventStatus)(eventEntity.Status ?? (byte)EventStatus.Draft);
                var requestedStatus = request.Status;

                // =====================================================================
                // ENFORCE VÒNG ĐỜI SỰ KIỆN (TRANSITION RULES)
                // - Không cho phép cập nhật sự kiện đã Closed/Cancelled
                // - Close/Cancel phải dùng API riêng (rõ ràng luồng nghiệp vụ)
                // =====================================================================
                if (currentStatus is EventStatus.Closed or EventStatus.Cancelled)
                {
                    throw new InvalidOperationException("Không thể cập nhật sự kiện đã kết thúc hoặc đã hủy");
                }

                if (requestedStatus != currentStatus)
                {
                    if (requestedStatus == EventStatus.Closed)
                    {
                        throw new InvalidOperationException("Vui lòng sử dụng API đóng sự kiện để chuyển sang trạng thái 'Đã kết thúc'");
                    }

                    if (requestedStatus == EventStatus.Cancelled)
                    {
                        throw new InvalidOperationException("Vui lòng sử dụng API hủy sự kiện để chuyển sang trạng thái 'Đã hủy'");
                    }

                    EnsureValidEventStatusTransition(currentStatus, requestedStatus);
                }

                // Cập nhật thông tin
                eventEntity.EventName = request.EventName;
                eventEntity.Description = request.Description;
                eventEntity.StartTime = DateTimeHelper.FromVietnamTimeToUtc(request.StartTime);
                eventEntity.EndTime = DateTimeHelper.FromVietnamTimeToUtc(request.EndTime);
                eventEntity.LocationName = request.LocationName;
                eventEntity.Latitude = request.Latitude;
                eventEntity.Longitude = request.Longitude;
                eventEntity.AllowRadius = request.AllowRadius;
                eventEntity.MaxParticipants = request.MaxParticipants;
                eventEntity.EventTypeID = request.EventTypeId;
                eventEntity.InstituteID = request.InstituteId;
                eventEntity.RegistrationDeadline = request.RegistrationDeadline.HasValue
                                    ? DateTimeHelper.FromVietnamTimeToUtc(request.RegistrationDeadline.Value)
                                    : null;
                eventEntity.EnableFaceVerification = request.EnableFaceVerification;
                eventEntity.Status = (byte)request.Status;
                eventEntity.UpdatedDate = DateTime.Now; // Auto-update timestamp

                await _context.SaveChangesAsync();

                _logger.LogInformation("Cập nhật sự kiện thành công với EventId: {EventId}", eventId);

                // ================= NOTIFICATION =================
                var updateMessages = new List<string>();

                if (oldStartTime != eventEntity.StartTime || oldEndTime != eventEntity.EndTime)
                {
                    updateMessages.Add("Thời gian sự kiện đã được thay đổi");
                }

                if (oldLocation != eventEntity.LocationName)
                {
                    updateMessages.Add("Địa điểm tổ chức đã được cập nhật");
                }

                if (oldStatus != eventEntity.Status)
                {
                    updateMessages.Add($"Trạng thái sự kiện đã thay đổi sang {((EventStatus)eventEntity.Status).ToDisplayName()}");
                }

                try
                {
                    if (updateMessages.Any())
                    {
                        await _notificationService.CreateEventUpdateNotificationsAsync(
                            eventEntity.EventID,
                            eventEntity.EventName,
                            string.Join(". ", updateMessages)
                        );
                    }
                }
                catch (Exception ex)
                {
                    // Notification KHÔNG được làm fail nghiệp vụ chính
                    _logger.LogError(ex,
                        "Không thể tạo thông báo cập nhật sự kiện: EventId {EventId}",
                        eventEntity.EventID);
                }

                if (actorUserId.HasValue)
                {
                    try
                    {
                        var actionDetail = updateMessages.Any()
                            ? string.Join(". ", updateMessages)
                            : "Cập nhật thông tin sự kiện";

                        await _notificationService.CreateActorEventActionConfirmationAsync(
                            actorUserId.Value,
                            eventEntity.EventID,
                            eventEntity.EventName,
                            "cập nhật",
                            actionDetail,
                            eventEntity.UpdatedDate?.Ticks);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(
                            ex,
                            "Không thể tạo thông báo xác nhận thao tác cập nhật sự kiện cho actor: EventId {EventId}, ActorUserId {UserId}",
                            eventEntity.EventID,
                            actorUserId.Value);
                    }
                }

                // Return updated event detail
                return await GetEventByIdAsync(eventId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật sự kiện với EventId: {EventId}", eventId);
                throw;
            }
        }

        /// <summary>
        /// Đóng sự kiện (Ongoing -> Closed)
        /// API riêng để đóng sự kiện rõ ràng, không dùng UpdateEventAsync.
        /// </summary>
        public async Task<EventDetailDto> CloseEventAsync(int eventId, int? unitId = null, int? instituteId = null, int? actorUserId = null)
        {
            var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);

            var eventEntity = await _context.Events
                .FirstOrDefaultAsync(e => e.EventID == eventId);

            if (eventEntity == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
            }

            if (scopeInstituteId.HasValue && eventEntity.InstituteID != scopeInstituteId.Value)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền đóng sự kiện của viện này");
            }

            var currentStatus = (EventStatus)(eventEntity.Status ?? (byte)EventStatus.Draft);
            if (currentStatus != EventStatus.Ongoing)
            {
                throw new InvalidOperationException("Chỉ có thể đóng sự kiện khi sự kiện đang diễn ra");
            }

            eventEntity.Status = (byte)EventStatus.Closed;
            eventEntity.UpdatedDate = DateTime.Now;
            await _context.SaveChangesAsync();

            try
            {
                await _notificationService.CreateEventUpdateNotificationsAsync(
                    eventEntity.EventID,
                    eventEntity.EventName,
                    "Sự kiện đã được đóng (Đã kết thúc)"
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không thể tạo thông báo đóng sự kiện: EventId {EventId}", eventEntity.EventID);
            }

            if (actorUserId.HasValue)
            {
                try
                {
                    await _notificationService.CreateActorEventActionConfirmationAsync(
                        actorUserId.Value,
                        eventEntity.EventID,
                        eventEntity.EventName,
                        "đóng",
                        "Chuyển trạng thái sang Đã kết thúc",
                        eventEntity.UpdatedDate?.Ticks);
                }
                catch (Exception ex)
                {
                    _logger.LogError(
                        ex,
                        "Không thể tạo thông báo xác nhận thao tác đóng sự kiện cho actor: EventId {EventId}, ActorUserId {UserId}",
                        eventEntity.EventID,
                        actorUserId.Value);
                }
            }

            return await GetEventByIdAsync(eventId)
                ?? throw new InvalidOperationException("Không thể lấy lại thông tin sự kiện sau khi đóng");
        }

        /// <summary>
        /// Hủy sự kiện (Draft/Open/Ongoing -> Cancelled)
        /// API riêng để hủy sự kiện rõ ràng, không dùng UpdateEventAsync.
        /// </summary>
        public async Task<EventDetailDto> CancelEventAsync(int eventId, string? reason, int? unitId = null, int? instituteId = null, int? actorUserId = null)
        {
            var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);

            var eventEntity = await _context.Events
                .FirstOrDefaultAsync(e => e.EventID == eventId);

            if (eventEntity == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
            }

            if (scopeInstituteId.HasValue && eventEntity.InstituteID != scopeInstituteId.Value)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền hủy sự kiện của viện này");
            }

            var currentStatus = (EventStatus)(eventEntity.Status ?? (byte)EventStatus.Draft);
            if (currentStatus is EventStatus.Closed or EventStatus.Cancelled)
            {
                throw new InvalidOperationException("Không thể hủy sự kiện đã kết thúc hoặc đã hủy");
            }

            eventEntity.Status = (byte)EventStatus.Cancelled;
            eventEntity.UpdatedDate = DateTime.Now;
            await _context.SaveChangesAsync();

            try
            {
                await _notificationService.CreateEventCancellationNotificationsAsync(
                    eventEntity.EventID,
                    eventEntity.EventName,
                    reason
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không thể tạo thông báo hủy sự kiện: EventId {EventId}", eventEntity.EventID);
            }

            if (actorUserId.HasValue)
            {
                try
                {
                    await _notificationService.CreateActorEventActionConfirmationAsync(
                        actorUserId.Value,
                        eventEntity.EventID,
                        eventEntity.EventName,
                        "hủy",
                        string.IsNullOrWhiteSpace(reason)
                            ? null
                            : $"Lý do: {reason.Trim()}",
                        eventEntity.UpdatedDate?.Ticks);
                }
                catch (Exception ex)
                {
                    _logger.LogError(
                        ex,
                        "Không thể tạo thông báo xác nhận thao tác hủy sự kiện cho actor: EventId {EventId}, ActorUserId {UserId}",
                        eventEntity.EventID,
                        actorUserId.Value);
                }
            }

            return await GetEventByIdAsync(eventId)
                ?? throw new InvalidOperationException("Không thể lấy lại thông tin sự kiện sau khi hủy");
        }

        private static void EnsureValidEventStatusTransition(EventStatus currentStatus, EventStatus requestedStatus)
        {
            if (currentStatus == requestedStatus) return;

            var isValid = currentStatus switch
            {
                EventStatus.Draft => requestedStatus is EventStatus.Open,
                EventStatus.Open => requestedStatus is EventStatus.Ongoing,
                EventStatus.Ongoing => false,
                EventStatus.Closed => false,
                EventStatus.Cancelled => false,
                _ => false
            };

            if (!isValid)
            {
                throw new InvalidOperationException(
                    $"Không thể chuyển trạng thái sự kiện từ '{currentStatus.ToDisplayName()}' sang '{requestedStatus.ToDisplayName()}'");
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

        /// <summary>
        /// Kiểm tra tính hợp lệ của thời gian sự kiện theo các quy tắc nghiệp vụ
        /// </summary>
        private void ValidateEventDates(DateTime startTime, DateTime endTime, DateTime? registrationDeadline)
        {
            // Quy tắc 1: Thời gian kết thúc phải sau thời gian bắt đầu
            if (endTime <= startTime)
            {
                throw new InvalidOperationException("Thời gian kết thúc phải sau thời gian bắt đầu");
            }

            // Quy tắc 2: Hạn đăng ký phải trước thời gian bắt đầu sự kiện
            if (registrationDeadline.HasValue && registrationDeadline.Value >= startTime)
            {
                throw new InvalidOperationException("Hạn đăng ký phải trước thời gian bắt đầu sự kiện");
            }
        }

        private string BuildFullUrl(string? relativeUrl)
        {
            return _publicUrlBuilder.BuildAbsoluteUrl(relativeUrl) ?? string.Empty;
        }

        /// <summary>
        /// Get status name from status code
        /// </summary>
        private string GetStatusName(byte? status)
        {
            return status switch
            {
                0 => "Nháp",
                1 => "Mở đăng ký",
                2 => "Đang diễn ra",
                3 => "Đã kết thúc",
                4 => "Đã hủy",
                _ => "Không xác định"
            };
        }
    }
}
