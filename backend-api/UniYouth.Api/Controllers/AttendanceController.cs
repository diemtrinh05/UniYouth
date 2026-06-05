using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Attendance;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Shared.Extensions;
using UniYouth.Api.Shared.Helpers;
using UniYouth.Api.Shared.Idempotency;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// API xử lý nghiệp vụ điểm danh (Attendance)
    /// 
    /// PHÂN QUYỀN:
    /// - Chỉ Đoàn viên và Hội viên mới được phép điểm danh
    /// - Cán bộ và Quản trị viên KHÔNG được điểm danh (chỉ quản lý)
    /// - Yêu cầu xác thực bằng JWT
    /// 
    /// ENDPOINT CHÍNH:
    /// - POST /api/attendance/checkin : Thực hiện điểm danh cho sự kiện
    /// 
    /// LUỒNG ĐIỂM DANH:
    /// 1. Người dùng quét mã QR bằng ứng dụng
    /// 2. ứng dụng lấy vị trí GPS hiện tại
    /// 3. Gửi request gồm QRToken + tọa độ GPS
    /// 4. Server kiểm tra toàn bộ điều kiện nghiệp vụ
    /// 5. Server ghi nhận attendance
    /// 6. Trả kết quả điểm danh cho người dùng
    /// 
    /// LƯU Ý BẢO MẬT:
    /// - GPS từ client không được tin tưởng tuyệt đối
    /// - Các luật điểm danh không hợp lệ vẫn được ghi nhận để audit
    /// - Hệ thống có ràng buộc UNIQUE để chống điểm danh trùng
    /// </summary>
    [ApiController]
    [Route("api/attendance")]
    [Authorize(Roles = "DoanVien,HoiVien")]
    public class AttendanceController : ControllerBase
    {
        private readonly IAttendanceService _attendanceService;
        private readonly ILogger<AttendanceController> _logger;

        public AttendanceController(
            IAttendanceService attendanceService,
            ILogger<AttendanceController> logger)
        {
            _attendanceService = attendanceService;
            _logger = logger;
        }

        /// <summary>
        /// Check in attendance cho sự kiện
        /// </summary>
        /// <param name="request">QR token và GPS coordinates</param>
        /// <returns>200 OK với kết quả check-in</returns>
        /// <response code="200">Check-in thành công hoặc không hợp lệ (cả 2 đều trả về 200)</response>
        /// <response code="400">Request không hợp lệ hoặc vi phạm business rules</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không có quyền (phải là DoanVien/HoiVien)</response>
        /// <response code="404">Không tìm thấy QR code hoặc sự kiện</response>
        [HttpPost("checkin")]
        [Idempotency]
        [EnableRateLimiting("AttendanceCheckIn")]
        [ProducesResponseType(typeof(ApiResponseDto<CheckInResultDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> CheckIn([FromBody] CheckInRequestDto request)
        {
            // =====================================================================
            // Lấy thông tin USER từ JWT
            // =====================================================================
            //var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("Token JWT không hợp lệ hoặc thiếu UserID claim");
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            // =====================================================================
            // Lấy thông tin CLIENT (PHỤC VỤ AUDIT & BẢO MẬT)
            // =====================================================================
            var ipAddress = ClientIpHelper.GetClientIpAddress(HttpContext);
            var userAgent = HttpContext.Request.Headers["User-Agent"].ToString();
            var deviceInfo = string.IsNullOrWhiteSpace(request.DeviceInfo)
                ? userAgent
                : request.DeviceInfo.Trim();

            if (!string.IsNullOrEmpty(deviceInfo) && deviceInfo.Length > 255)
            {
                deviceInfo = deviceInfo[..255];
            }

            _logger.LogInformation(
                "Yêu cầu điểm danh: User {UserId}, Token {Token}, " +
                "GPS ({Lat}, {Lon}), IP {IP}",
                userId,
                request.QRToken.Substring(0, Math.Min(10, request.QRToken.Length)) + "...",
                request.Latitude,
                request.Longitude,
                ipAddress);

            // =====================================================================
            // GỌI SERVICE XỬ LÝ NGHIỆP VỤ
            // =====================================================================
            var result = await _attendanceService.CheckInAsync(
                request,
                userId,
                ipAddress,
                deviceInfo,
                userAgent);

            // =====================================================================
            // TRẢ KẾT QUẢ (CHUẨN HÓA RESPONSE ENVELOPE)
            // - Luôn trả 200 OK nếu hệ thống xử lý được và đã tạo record điểm danh
            // - Client dựa vào result.IsValid để biết kết quả hợp lệ hay không
            // =====================================================================
            return Ok(new ApiResponseDto<CheckInResultDto>
            {
                Success = true,
                Message = result.Message,
                Data = result
            });
        }

        [HttpPost("checkin/requirements")]
        [ProducesResponseType(typeof(ApiResponseDto<CheckInRequirementsDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetCheckInRequirements([FromBody] CheckInRequirementsRequestDto request)
        {
            var result = await _attendanceService.GetCheckInRequirementsAsync(request.QRToken);

            return Ok(new ApiResponseDto<CheckInRequirementsDto>
            {
                Success = true,
                Message = "Lấy yêu cầu điểm danh thành công",
                Data = result
            });
        }

        /// <summary>
        /// Lấy lịch sử điểm danh của người dùng hiện tại
        /// </summary>
        [HttpGet("my-history")]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<AttendanceHistoryDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetMyAttendanceHistory([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
        {
            //var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();

            const int MaxPageSize = 100;
            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1) pageSize = 20;
            if (pageSize > MaxPageSize) pageSize = MaxPageSize;

            var result = await _attendanceService.GetMyHistoryAsync(userId, pageNumber, pageSize);

            return Ok(new ApiResponseDto<PaginatedResultDto<AttendanceHistoryDto>>
            {
                Success = true,
                Message = "Lấy lịch sử điểm danh thành công",
                Data = result
            });
        }

        /// <summary>
        /// Kiểm tra người dùng đã điểm danh cho một sự kiện hay chưa
        /// </summary>
        /// <param name="eventId">ID của sự kiện</param>
        [HttpGet("check-status/{eventId:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        public async Task<IActionResult> CheckAttendanceStatus(int eventId)
        {
            //var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            bool checkedIn = await _attendanceService.HasCheckedInAsync(eventId, userId);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Lấy trạng thái điểm danh thành công",
                Data = new
                {
                    eventId,
                    hasCheckedIn = checkedIn
                }
            });
        }
    }
}

