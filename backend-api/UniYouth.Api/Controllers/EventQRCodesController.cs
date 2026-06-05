using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events.Qr;
using UniYouth.Api.Shared.Constants;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// API quản lý mã QR cho sự kiện
    /// 
    /// AUTHORIZATION:
    /// - Chỉ CanBo và Admin mới có quyền quản lý QR codes
    /// - DoanVien và HoiVien KHÔNG được phép truy cập
    /// - JWT authentication bắt buộc
    /// 
    /// ENDPOINTS:
    /// - POST /api/events/{eventId}/qrcode - Tạo QR code mới
    /// - GET /api/events/{eventId}/qrcode - Xem danh sách QR codes
    /// - PUT /api/events/qrcode/{qrId}/deactivate - Vô hiệu hóa QR code
    /// 
    /// QR CODE WORKFLOW:
    /// 1. CanBo tạo QR code trước khi sự kiện diễn ra
    /// 2. QR code tự động active trong khoảng ValidFrom -> ValidUntil
    /// 3. Sinh viên quét QR để điểm danh (xử lý API khác)
    /// 4. CanBo có thể vô hiệu hóa QR nếu cần
    /// 5. Hệ thống tự động từ chối các QR đã hết hạn hoặc bị vô hiệu hóa
    /// </summary>
    [ApiController]
    [Route("api/events")]
    [Authorize(Roles = RoleNames.CanBo + "," + RoleNames.Admin)]
    [EnableRateLimiting("Qr")]
    public class EventQRCodesController : ControllerBase
    {
        private readonly IEventQRCodeService _qrCodeService;
        private readonly ILogger<EventQRCodesController> _logger;

        public EventQRCodesController(
            IEventQRCodeService qrCodeService,
            ILogger<EventQRCodesController> logger)
        {
            _qrCodeService = qrCodeService;
            _logger = logger;
        }

        /// <summary>
        /// Tạo QR code mới cho sự kiện
        /// </summary>
        /// <param name="eventId">ID sự kiện</param>
        /// <param name="request">Thông tin QR code (thời gian hiệu lực, giới hạn quét)</param>
        /// <returns>201 Created với thông tin QR code bao gồm QRToken</returns>
        /// <response code="201">QR code được tạo thành công</response>
        /// <response code="400">Dữ liệu không hợp lệ hoặc sự kiện không thể tạo QR</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không có quyền (phải là CanBo/Admin)</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        [HttpPost("{eventId:int}/qrcode")]
        [ProducesResponseType(typeof(ApiResponseDto<EventQrResponseDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GenerateQRCode(
            int eventId,
            [FromBody] GenerateEventQrRequestDto request)
        {
            // Lấy UserID từ JWT
            //var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("Token JWT không hợp lệ hoặc thiếu UserID claim");
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            _logger.LogInformation(
                "User {UserId} đang tạo QR code cho Event {EventId}",
                userId, eventId);

            // Gửi service xử lý toàn bộ nghiệp vụ
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

            var result = await _qrCodeService.GenerateQRCodeAsync(eventId, request, userId, unitId, instituteId);

            // Return 201 Created
            return CreatedAtAction(
                nameof(GetEventQRCodes),
                new { eventId },
                new ApiResponseDto<EventQrResponseDto>
                {
                    Success = true,
                    Message = "QR code đã được tạo thành công",
                    Data = result
                });
        }

        /// <summary>
        /// Lấy danh sách tất cả QR codes của sự kiện
        /// Bao gồm cả QR active và inactive để quản lý
        /// </summary>
        /// <param name="eventId">ID sự kiện</param>
        /// <returns>200 OK với danh sách QR codes</returns>
        /// <response code="200">Lấy danh sách thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không có quyền</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        [HttpGet("{eventId:int}/qrcode")]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<EventQrListItemDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetEventQRCodes(int eventId, [FromQuery] GetEventQRCodesQueryDto query)
        {
            _logger.LogInformation("Đang lấy danh sách QR codes cho Event {EventId}", eventId);

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

            var qrCodes = await _qrCodeService.GetEventQRCodesAsync(eventId, query, unitId, instituteId);

            return Ok(new ApiResponseDto<PaginatedResultDto<EventQrListItemDto>>
            {
                Success = true,
                Message = $"Tìm thấy {qrCodes.TotalCount} QR code(s)",
                Data = qrCodes
            });
        }

        /// <summary>
        /// Vô hiệu hóa QR code thủ công
        /// Sử dụng khi cần thu hồi QR trước thời hạn (vd: bị lỗi, sự kiện hủy)
        /// </summary>
        /// <param name="qrId">ID của QR code cần vô hiệu hóa</param>
        /// <returns>200 OK với xác nhận</returns>
        /// <response code="200">Vô hiệu hóa thành công</response>
        /// <response code="400">QR code đã bị vô hiệu hóa trước đó</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không có quyền</response>
        /// <response code="404">Không tìm thấy QR code</response>
        [HttpPut("qrcode/{qrId:int}/deactivate")]
        [ProducesResponseType(typeof(ApiResponseDto<DeactivateQrResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeactivateQRCode(int qrId)
        {
            // Extract UserID from JWT claims
            //var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("Token JWT không hợp lệ hoặc thiếu UserID claim");
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            _logger.LogInformation(
                "User {UserId} đang vô hiệu hóa QR code {QRID}",
                userId, qrId);

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

            var result = await _qrCodeService.DeactivateQRCodeAsync(qrId, userId, unitId, instituteId);

            return Ok(new ApiResponseDto<DeactivateQrResponseDto>
            {
                Success = true,
                Message = result.Message,
                Data = result
            });
        }

        /// <summary>
        /// Xem chi tiết một QR code (phục vụ Web quản lý)
        /// </summary>
        /// <param name="qrId">ID của QR code</param>
        /// <returns>200 OK với chi tiết QR code</returns>
        /// <response code="200">Thành công</response>
        /// <response code="403">Không có quyền truy cập</response>
        /// <response code="404">Không tìm thấy QR code</response>
        [HttpGet("qrcode/{qrId:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<QrCodeDetailResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetQRCodeDetail(int qrId, CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var isAdmin = User.IsInRole(RoleNames.Admin);

            var detail = await _qrCodeService.GetQRCodeDetailAsync(qrId, userId, isAdmin, cancellationToken);

            return Ok(new ApiResponseDto<QrCodeDetailResponseDto>
            {
                Success = true,
                Message = "Lấy chi tiết QR code thành công",
                Data = detail
            });
        }
    }
}

