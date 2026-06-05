using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Shared.Constants;
using UniYouth.Api.Shared.Enums;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// Controller quản lý sự kiện
    /// Hỗ trợ cả Mobile App (người tham gia) và Web (cán bộ quản lý)
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Tất cả API đều yêu cầu đăng nhập
    [Produces("application/json")]
    public class EventsController : ControllerBase
    {
        private readonly IEventService _eventService;
        private readonly IEventRegistrationService _eventRegistrationService;
        private readonly ILogger<EventsController> _logger;

        public EventsController(
            IEventService eventService,
            IEventRegistrationService eventRegistrationService,
            ILogger<EventsController> logger)
        {
            _eventService = eventService;
            _eventRegistrationService = eventRegistrationService;
            _logger = logger;
        }

        /// <summary>
        /// Lấy danh sách sự kiện (DÀNH CHO MOBILE APP - Đoàn viên/Hội viên)
        /// Chỉ trả về các sự kiện đang mở, đang diễn ra hoặc đã kết thúc
        /// </summary>
        /// <param name="pageNumber">Số trang (mức đánh: 1)</param>
        /// <param name="pageSize">Số bản ghi mới trang (mức đánh: 10, tối đa: 50)</param>
        /// <param name="eventTypeId">Lực theo loại sự kiện</param>
        /// <param name="instituteId">Lực theo viện</param>
        /// <param name="startDate">Lực theo thời gian bắt đầu (từ ngày)</param>
        /// <param name="endDate">Lực theo thời gian bắt đầu (đến ngày)</param>
        /// <returns>Danh sách sự kiện có phân trang</returns>
        /// <response code="200">Trả về danh sách sự kiện</response>
        /// <response code="401">Người dùng chưa đăng nhập</response>
        /// <remarks>
        /// Ví dụ request:
        /// 
        ///     GET /api/events?pageNumber=1&amp;pageSize=10&amp;eventTypeId=1
        /// 
        /// API này được thiết kế cho Mobile App để người dùng xem các sự kiện có thể tham gia.
        /// Kết quả được sắp xếp theo thời gian bắt đầu tăng dần (sự kiện sắp diễn ra trước).
        /// </remarks>
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<EventListItemDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetEvents(
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] int? status = null,
            [FromQuery] int? eventTypeId = null,
            [FromQuery] int? instituteId = null,
            [FromQuery] string? q = null,
            [FromQuery] string? sortBy = null,
            [FromQuery] string? sortDir = null,
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            // Kiểm tra tham số phân trang
            if (pageNumber < 1)
            {
                pageNumber = 1;
            }

            if (pageSize < 1 || pageSize > 50)
            {
                pageSize = 10; // Mặc định là 10 nếu không hợp lệ
            }

            if (status.HasValue &&
                status.Value != (int)EventStatus.Open &&
                status.Value != (int)EventStatus.Ongoing &&
                status.Value != (int)EventStatus.Closed)
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Status chỉ hỗ trợ Open, Ongoing hoặc Closed"
                });
            }

            _logger.LogInformation(
                "Lấy danh sách sự kiện - Trang: {Page}, Kích thước trang: {Size}, Status: {Status}, EventTypeId: {TypeId}, InstituteId: {InstituteId}",
                pageNumber, pageSize, status, eventTypeId, instituteId);

            var result = await _eventService.GetEventsAsync(
                pageNumber,
                pageSize,
                status,
                eventTypeId,
                instituteId,
                q,
                sortBy,
                sortDir,
                startDate,
                endDate);

            return Ok(new ApiResponseDto<PaginatedResultDto<EventListItemDto>>
            {
                Success = true,
                Message = "Lấy danh sách sự kiện thành công",
                Data = result
            });
        }

        [HttpGet("admin")]
        [Authorize(Roles = "CanBo,Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<EventListItemDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> GetEventsForAdmin(
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] int? status = null,
            [FromQuery] string? q = null,
            [FromQuery] int? eventTypeId = null,
            [FromQuery] int? instituteId = null,
            [FromQuery] DateTime? startFrom = null,
            [FromQuery] DateTime? startTo = null,
            [FromQuery] string? sortBy = null,
            [FromQuery] string? sortDir = null)
        {
            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1 || pageSize > 100) pageSize = 10;

            _logger.LogInformation("Admin request danh sách sự kiện");

            int? unitId = null;
            int? scopeInstituteId = null;

            if (!User.IsInRole("Admin"))
            {
                unitId = User.GetUnitIdOrNull();
                scopeInstituteId = User.GetInstituteIdOrNull();

                if (!unitId.HasValue && !scopeInstituteId.HasValue)
                {
                    return StatusCode(StatusCodes.Status403Forbidden, new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Thiếu claim unitId/instituteId để giới hạn phạm vi dữ liệu"
                    });
                }

                // CanBo: không cho phép từ truyền instituteId ra ngoài scope
                instituteId = scopeInstituteId;
            }

            var result = await _eventService.GetEventsForAdminAsync(
                pageNumber: pageNumber,
                pageSize: pageSize,
                status: status,
                q: q,
                eventTypeId: eventTypeId,
                startFrom: startFrom,
                startTo: startTo,
                sortBy: sortBy,
                sortDir: sortDir,
                unitId: unitId,
                instituteId: instituteId);

            return Ok(new ApiResponseDto<PaginatedResultDto<EventListItemDto>>
            {
                Success = true,
                Message = "Lấy danh sách sự kiện (admin) thành công",
                Data = result
            });
        }


        /// <summary>
        /// Lấy chi tiết sự kiện theo ID (DÀNH CHO MOBILE APP)
        /// </summary>
        /// <param name="id">ID của sự kiện</param>
        /// <returns>Thông tin chi tiết sự kiện</returns>
        /// <response code="200">Trả về chi tiết sự kiện</response>
        /// <response code="401">Người dùng chưa đăng nhập</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        /// <remarks>
        /// Ví dụ request:
        /// 
        ///     GET /api/events/5
        /// 
        /// Trả về dãy thông tin chi tiết sự kiện bao gồm:
        /// - Thông tin cơ bản (tên, mô tả, thời gian, địa điểm)
        /// - Tọa độ GPS và bán kính check-in
        /// - Trạng thái đăng ký và số chỉ còn trống
        /// - Danh sách hình ảnh
        /// - Loại sự kiện và viện
        /// </remarks>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(ApiResponseDto<EventDetailDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetEventById(int id)
        {
            _logger.LogInformation("Lấy chi tiết sự kiện với EventId: {EventId}", id);

            var eventDetail = await _eventService.GetEventByIdAsync(id);

            if (eventDetail == null)
            {
                return NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Không tìm thấy sự kiện"
                });
            }

            return Ok(new ApiResponseDto<EventDetailDto>
            {
                Success = true,
                Message = "Lấy chi tiết sự kiện thành công",
                Data = eventDetail
            });
        }

        /// <summary>
        /// Tạo mới sự kiện (DÀNH CHO WEB QUẢN LÝ)
        /// Chỉ Cán bộ và Admin được phép thực hiện
        /// </summary>
        /// <param name="request">Dữ liệu tạo sự kiện</param>
        /// <returns>Thông tin sự kiện vừa tạo</returns>
        /// <response code="201">Tạo sự kiện thành công</response>
        /// <response code="400">Dữ liệu không hợp lệ hoặc vi phạm nghiệp vụ</response>
        /// <response code="401">Người dùng chưa đăng nhập</response>
        /// <response code="403">Không có quyền (không phải Cán bộ hoặc Admin)</response>
        /// <remarks>
        /// Sample request:
        /// 
        ///     POST /api/events
        ///     {
        ///         "eventName": "Hội thảo Khoa học Công nghệ 2024",
        ///         "description": "Hội thảo về AI và Machine Learning",
        ///         "startTime": "2024-12-30T08:00:00Z",
        ///         "endTime": "2024-12-30T17:00:00Z",
        ///         "locationName": "Hội trường A",
        ///         "latitude": 10.762622,
        ///         "longitude": 106.660172,
        ///         "allowRadius": 100,
        ///         "maxParticipants": 200,
        ///         "eventTypeId": 1,
        ///         "instituteId": 1,
        ///         "registrationDeadline": "2024-12-28T23:59:59Z",
        ///         "status": 0
        ///     }
        /// 
        /// Business Rules:
        /// - Thời gian kết thúc phải sau Thời gian bắt đầu
        /// - Thời hạn đăng ký phải trước Thời gian bắt đầu
        /// - MaxParticipants phải lớn hơn 0 (hoặc null nếu không giới hạn)
        /// - CreatedBy được đặt tự động từ JWT UserId
        /// </remarks>
        [HttpPost]
        [Authorize(Roles = "CanBo,Admin")] // Only CanBo and Admin
        [ProducesResponseType(typeof(ApiResponseDto<EventDetailDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> CreateEvent([FromBody] CreateEventRequestDto request)
        {
            // Validate model state
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            // Lấy UserId từ JWT
                //var userIdClaim = User.FindFirst("userId")?.Value;
                //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int createdBy))
                //{
                //    _logger.LogWarning("Claim userId không hợp lệ khi tạo sự kiện");
                //    return Unauthorized(new
                //    {
                //        message = "Token không hợp lệ"
                //    });
                //}
                var createdBy = User.GetUserId();
                _logger.LogInformation("Tạo sự kiện bởi UserId: {UserId}", createdBy);

                int? unitId = null;
                int? instituteId = null;

                if (!User.IsInRole("Admin"))
                {
                    unitId = User.GetUnitIdOrNull();
                    instituteId = User.GetInstituteIdOrNull();

                    if (!unitId.HasValue && !instituteId.HasValue)
                    {
                        return StatusCode(StatusCodes.Status403Forbidden, new ApiResponseDto<object>
                        {
                            Success = false,
                            Message = "Thiếu claim unitId/instituteId để giới hạn phạm vi dữ liệu"
                        });
                    }
                }

                var createdEvent = await _eventService.CreateEventAsync(request, createdBy, unitId, instituteId);

                // Return 201 Created with Location header
                return CreatedAtAction(
                    nameof(GetEventById),
                    new { id = createdEvent.EventId },
                    new ApiResponseDto<EventDetailDto>
                    {
                        Success = true,
                        Message = "Tạo sự kiện thành công",
                        Data = createdEvent
                    });
        }

        /// <summary>
        /// Cập nhật sự kiện (DÀNH CHO WEB QUẢN LÝ)
        /// Chỉ Cán bộ và Admin được phép thực hiện
        /// </summary>
        /// <param name="id">ID của sự kiện cần cập nhật</param>
        /// <param name="request">Dữ liệu cập nhật sự kiện</param>
        /// <returns>Thông tin sự kiện sau khi cập nhật</returns>
        /// <response code="200">Cập nhật thành công</response>
        /// <response code="400">Dữ liệu không hợp lệ hoặc vi phạm nghiệp vụ</response>
        /// <response code="401">Người dùng chưa đăng nhập</response>
        /// <response code="403">Không có quyền</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        /// <remarks>
        /// Sample request:
        /// 
        ///     PUT /api/events/5
        ///     {
        ///         "eventName": "Hội thảo Khoa học Công nghệ 2024 (Updated)",
        ///         "description": "Hội thảo về AI, ML và Data Science",
        ///         "startTime": "2024-12-30T08:00:00Z",
        ///         "endTime": "2024-12-30T18:00:00Z",
        ///         "locationName": "Hội trường B",
        ///         "latitude": 10.762622,
        ///         "longitude": 106.660172,
        ///         "allowRadius": 150,
        ///         "maxParticipants": 250,
        ///         "eventTypeId": 1,
        ///         "instituteId": 1,
        ///         "registrationDeadline": "2024-12-28T23:59:59Z",
        ///         "status": 1
        ///     }
        /// 
        /// Business Rules:
        /// - Quy tắc xác thực tương tự như CreateEvent
        /// - UpdatedDate được đặt tự động theo thời gian hiện tại
        /// </remarks>
        [HttpPut("{id}")]
        [Authorize(Roles = "CanBo,Admin")] // Only CanBo and Admin
        [ProducesResponseType(typeof(ApiResponseDto<EventDetailDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UpdateEvent(int id, [FromBody] UpdateEventRequestDto request)
        {
            // Validate model state
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            _logger.LogInformation("Cập nhật sự kiện với EventId: {EventId}", id);
            var actorUserId = User.GetUserId();

            int? unitId = null;
            int? instituteId = null;

            if (!User.IsInRole("Admin"))
            {
                unitId = User.GetUnitIdOrNull();
                instituteId = User.GetInstituteIdOrNull();

                if (!unitId.HasValue && !instituteId.HasValue)
                {
                    return StatusCode(StatusCodes.Status403Forbidden, new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Thiếu claim unitId/instituteId để giới hạn phạm vi dữ liệu"
                    });
                }
            }

            var updatedEvent = await _eventService.UpdateEventAsync(id, request, unitId, instituteId, actorUserId);

            if (updatedEvent == null)
            {
                return NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Không tìm thấy sự kiện để cập nhật"
                });
            }

            return Ok(new ApiResponseDto<EventDetailDto>
            {
                Success = true,
                Message = "Cập nhật sự kiện thành công",
                Data = updatedEvent
            });
        }

        /// <summary>
        /// Lấy danh sách đăng ký tham gia sự kiện (Web quản lý)
        /// - Admin: xem mới event
        /// - CanBo: chỉ xem event do mình tạo
        /// </summary>
        [HttpGet("{eventId:int}/registrations")]
        [Authorize(Roles = RoleNames.CanBo + "," + RoleNames.Admin)]
        [ProducesResponseType(typeof(ApiResponseDto<EventRegistrationListResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetEventRegistrations(
            int eventId,
            [FromQuery] int? status = null,
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 20,
            CancellationToken cancellationToken = default)
        {
            var userId = User.GetUserId();
            var isAdmin = User.IsInRole(RoleNames.Admin);

            var result = await _eventRegistrationService.GetEventRegistrationsAsync(
                eventId,
                userId,
                isAdmin,
                status,
                pageNumber,
                pageSize,
                cancellationToken);

            return Ok(new ApiResponseDto<EventRegistrationListResponseDto>
            {
                Success = true,
                Message = "Lấy danh sách đăng ký sự kiện thành công",
                Data = result
            });
        }

        /// <summary>
        /// Đóng sự kiện (Close) - chuyển trạng thái từ Đang diễn ra sang Đã kết thúc
        /// Chỉ Cán bộ và Admin được phép thực hiện
        /// </summary>
        [HttpPut("{id:int}/close")]
        [Authorize(Roles = "CanBo,Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<EventDetailDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> CloseEvent(int id)
        {
            var actorUserId = User.GetUserId();
            int? unitId = null;
            int? instituteId = null;

            if (!User.IsInRole("Admin"))
            {
                unitId = User.GetUnitIdOrNull();
                instituteId = User.GetInstituteIdOrNull();

                if (!unitId.HasValue && !instituteId.HasValue)
                {
                    return StatusCode(StatusCodes.Status403Forbidden, new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Thiếu claim unitId/instituteId để giới hạn phạm vi dữ liệu"
                    });
                }
            }

            var result = await _eventService.CloseEventAsync(id, unitId, instituteId, actorUserId);
            return Ok(new ApiResponseDto<EventDetailDto>
            {
                Success = true,
                Message = "Đóng sự kiện thành công",
                Data = result
            });
        }

        /// <summary>
        /// Hủy sự kiện (Cancel) - chuyển trạng thái sang Đã hủy
        /// Chỉ Cán bộ và Admin được phép thực hiện
        /// </summary>
        [HttpPut("{id:int}/cancel")]
        [Authorize(Roles = "CanBo,Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<EventDetailDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> CancelEvent(int id, [FromBody] CancelEventRequestDto? request = null)
        {
            var actorUserId = User.GetUserId();
            int? unitId = null;
            int? instituteId = null;

            if (!User.IsInRole("Admin"))
            {
                unitId = User.GetUnitIdOrNull();
                instituteId = User.GetInstituteIdOrNull();

                if (!unitId.HasValue && !instituteId.HasValue)
                {
                    return StatusCode(StatusCodes.Status403Forbidden, new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Thiếu claim unitId/instituteId để giới hạn phạm vi dữ liệu"
                    });
                }
            }

            var result = await _eventService.CancelEventAsync(id, request?.Reason, unitId, instituteId, actorUserId);
            return Ok(new ApiResponseDto<EventDetailDto>
            {
                Success = true,
                Message = "Hủy sự kiện thành công",
                Data = result
            });
        }
    }
}

