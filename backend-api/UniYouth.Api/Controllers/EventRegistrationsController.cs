using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events;
using UniYouth.Api.Shared.Extensions;
using UniYouth.Api.Shared.Idempotency;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// API đăng ký tham gia sự kiện
    /// 
    /// CHỨC NĂNG:
    /// - Cho phép Đoàn viên / Hội viên đăng ký tham gia sự kiện
    /// - Cho phép hủy đăng ký khi còn trong thời gian cho phép
    /// - Cho phép xem trạng thái đăng ký của bản thân
    /// 
    /// PHÂN QUYỀN:
    /// - Chỉ áp dụng cho các vai trò: DoanVien, HoiVien
    /// - Cán bộ (CanBo) và Quản trị viên (Admin) sử dụng các API quản lý riêng
    /// - Bắt buộc xác thực bằng JWT
    /// 
    /// ENDPOINTS:
    /// - POST /api/events/{eventId}/register - Register for event
    /// - DELETE /api/events/{eventId}/register - Cancel registration
    /// </summary>
    [ApiController]
    [Route("api/events")]
    [Authorize(Roles = "DoanVien,HoiVien")]
    public class EventRegistrationsController : ControllerBase
    {
        private readonly IEventRegistrationService _registrationService;
        private readonly ILogger<EventRegistrationsController> _logger;

        public EventRegistrationsController(
            IEventRegistrationService registrationService,
            ILogger<EventRegistrationsController> logger)
        {
            _registrationService = registrationService;
            _logger = logger;
        }

        /// <summary>
        /// Đăng ký tham gia sự kiện cho người dùng hiện tại
        /// </summary>
        /// <param name="eventId">Event ID from route</param>
        /// <returns>201 Created kèm thông tin đăng ký nếu thành công</returns>
        /// <response code="201">Successfully registered for event</response>
        /// <response code="400">Already registered, event full, or registration closed</response>
        /// <response code="401">Unauthorized - JWT token missing or invalid</response>
        /// <response code="403">Forbidden - User role not allowed</response>
        /// <response code="404">Event not found</response>
        [HttpPost("{eventId:int}/register")]
        [Idempotency]
        [ProducesResponseType(typeof(ApiResponseDto<EventRegistrationResultDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> RegisterForEvent(int eventId)
        {
            // Lấy UserId từ JWT 
            // The JWT should contain a claim with the user's ID
            //var userIdClaim = User.FindFirst("userId")?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("Token JWT không hợp lệ hoặc thiếu UserID claim");
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            _logger.LogInformation("Người dùng {UserId} đang thực hiện đăng ký sự kiện {EventId}", userId, eventId);

            // Gửi service để xử lý toàn bộ nghiệp vụ
            var result = await _registrationService.RegisterForEventAsync(eventId, userId);

            // Return 201 Created with registration details
            return CreatedAtAction(
                nameof(RegisterForEvent),
                new { eventId },
                new ApiResponseDto<EventRegistrationResultDto>
                {
                    Success = true,
                    Message = "Đăng kí sự kiện thành công",
                    Data = result
                });
        }

        /// <summary>
        /// Hủy đăng ký tham gia sự kiện của người dùng hiện tại
        /// </summary>
        /// <param name="eventId">ID của sự kiện</param>
        /// <param name="request">Lư do hủy đăng ký (không bắt buộc)</param>
        /// <returns>
        /// 200 OK nếu hủy đăng ký thành công
        /// </returns>
        /// <response code="200">Successfully cancelled registration</response>
        /// <response code="400">Not registered or event already closed</response>
        /// <response code="401">Unauthorized - JWT token missing or invalid</response>
        /// <response code="403">Forbidden - User role not allowed</response>
        /// <response code="404">Event not found or user not registered</response>
        [HttpDelete("{eventId:int}/register")]
        [ProducesResponseType(typeof(ApiResponseDto<EventRegistrationResultDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> CancelRegistration(
            int eventId,
            [FromBody] CancelRegistrationRequestDto? request = null)
        {
            // Lấy UserId từ JWT
            //var userIdClaim = User.FindFirst("userId")?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("Token JWT không hợp lệ hoặc thiếu UserID claim");
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            _logger.LogInformation(
                "Người dùng {UserId} đang thực hiện hủy đăng ký sự kiện {EventId}",
                userId, eventId);

            // Call service to handle all business logic
            var result = await _registrationService.CancelRegistrationAsync(
                eventId,
                userId,
                request?.CancellationReason);

            return Ok(new ApiResponseDto<EventRegistrationResultDto>
            {
                Success = true,
                Message = "Hủy đăng kí sự kiện thành công",
                Data = result
            });
        }

        /// <summary>
        /// Lấy thông tin đăng kí sự kiện của người dùng hiện tại
        /// </summary>
        /// <param name="eventId">ID của sự kiện</param>
        /// <returns>
        /// Thông tin đăng kí nếu người dùng đăng kí,
        /// hoặc 404 nếu chưa đăng kí
        /// </returns>
        [HttpGet("{eventId:int}/my-registration")]
        [ProducesResponseType(typeof(ApiResponseDto<EventRegistrationResultDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetMyRegistration(int eventId)
        {
            //var userIdClaim = User.FindFirst("userId")?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            var registration = await _registrationService.GetMyRegistrationAsync(eventId, userId);

            if (registration == null)
                return NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Bạn chưa đăng ký tham gia sự kiện này"
                });

            return Ok(new ApiResponseDto<EventRegistrationResultDto>
            {
                Success = true,
                Message = "Lấy thông tin đăng kí thành công",
                Data = registration
            });
        }
    }
}

