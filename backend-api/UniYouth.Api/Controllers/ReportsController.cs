using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Reports;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// API báo cáo và thống kê dành cho quản trị
    /// 
    /// PHÂN QUYỀN:
    /// - Chỉ người dùng có vai trò CanBo hoặc Admin mới được truy cập
    /// - Đoàn viên / Hội viên KHÔNG có quyền xem báo cáo
    /// 
    /// ENDPOINTS CHÍNH:
    /// - GET /api/events/{eventId}/attendance-stats : Thống kê điểm danh của một sự kiện
    /// - GET /api/events/{eventId}/attendances      : Danh sách chi tiết người đã điểm danh
    /// - GET /api/events/all/attendance-stats       : Thống kê tổng hợp tất cả sự kiện
    /// 
    /// USE CASE:
    /// - Web admin dashboard: theo dõi tình hình tham gia sự kiện
    /// - Quản lý sự kiện: đánh giá hiệu quả tổ chức
    /// - Báo cáo: phục vụ tổng hợp số liệu cho lãnh đạo
    /// </summary>
    [ApiController]
    [Route("api/events")]
    [Authorize(Roles = "CanBo,Admin")]
    public class ReportsController : ControllerBase
    {
        private readonly IReportingService _reportingService;
        private readonly ILogger<ReportsController> _logger;

        public ReportsController(
            IReportingService reportingService,
            ILogger<ReportsController> logger)
        {
            _reportingService = reportingService;
            _logger = logger;
        }

        /// <summary>
        /// Lấy thống kê điểm danh của sự kiện
        /// </summary>
        /// <param name="eventId">ID sự kiện</param>
        /// <returns>200 OK với thống kê điểm danh</returns>
        /// <response code="200">Thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không có quyền (phải là CanBo/Admin)</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        [HttpGet("{eventId:int}/attendance-stats")]
        [ProducesResponseType(typeof(ApiResponseDto<EventAttendanceStatsDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetEventAttendanceStats(int eventId)
        {
            _logger.LogInformation(
                "Yêu cầu lấy thống kê điểm danh Event {EventId}",
                eventId);

            // ================================================================
            // GỌI SERVICE LẤY THỐNG KÊ
            // ================================================================
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

            var stats = await _reportingService.GetEventAttendanceStatsAsync(eventId, unitId, instituteId);

            return Ok(new ApiResponseDto<EventAttendanceStatsDto>
            {
                Success = true,
                Message = "Lấy thống kê điểm danh thành công",
                Data = stats
            });
        }

        /// <summary>
        /// Lấy danh sách chi tiết người dă điểm danh
        /// </summary>
        /// <param name="eventId">ID sự kiện</param>
        /// <returns>200 OK với danh sách chi tiết</returns>
        /// <response code="200">Thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không có quyền</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        [HttpGet("{eventId:int}/attendances")]
        [ProducesResponseType(typeof(ApiResponseDto<EventAttendancesListResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetEventAttendances(int eventId, [FromQuery] GetEventAttendancesQueryDto query)
        {
            _logger.LogInformation(
                "Yêu cầu lấy danh sách điểm danh chi tiết Event {EventId}",
                eventId);

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

            var result = await _reportingService.GetEventAttendancesAsync(eventId, query, unitId, instituteId);

            return Ok(new ApiResponseDto<EventAttendancesListResponseDto>
            {
                Success = true,
                Message = $"Tìm thấy {result.Summary.TotalRecords} bản ghi điểm danh",
                Data = result
            });
        }

        /// <summary>
        /// Lấy tổng hợp thống kê tất cả sự kiện
        /// </summary>
        /// <returns>200 OK với danh sách thống kê các sự kiện</returns>
        /// <response code="200">Thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không có quyền</response>
        [HttpGet("all/attendance-stats")]
        [ProducesResponseType(typeof(ApiResponseDto<AllEventsAttendanceStatsResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> GetAllEventsAttendanceStats([FromQuery] GetAllEventsAttendanceStatsQueryDto query)
        {
            _logger.LogInformation("Yêu cầu lấy thống kê tổng hợp điểm danh của tất cả sự kiện");

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

            var result = await _reportingService.GetAllEventsAttendanceStatsAsync(query, unitId, instituteId);

            return Ok(new ApiResponseDto<AllEventsAttendanceStatsResponseDto>
            {
                Success = true,
                Message = $"Tìm thấy thống kê của {result.Summary.TotalEvents} sự kiện",
                Data = result
            });
        }
        /// <summary>
        /// Dashboard quan sát vẫn hành thông báo (success/fail/retry/delay)
        /// </summary>
        /// <param name="query">Bộ lọc thời gian, channel và số lượng lại gần nhất</param>
        /// <returns>200 OK với dữ liệu observability</returns>
        /// <response code="200">Thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="403">Không có quyền (chỉ Admin)</response>
        [HttpGet("notification-observability")]
        [Authorize(Roles = "Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<NotificationObservabilityResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> GetNotificationObservability([FromQuery] GetNotificationObservabilityQueryDto query)
        {
            _logger.LogInformation(
                "Yêu cầu lấy dashboard quan sát thông báo. From={From}, To={To}, Channel={Channel}",
                query.From,
                query.To,
                query.Channel);

            var result = await _reportingService.GetNotificationObservabilityAsync(query);

            return Ok(new ApiResponseDto<NotificationObservabilityResponseDto>
            {
                Success = true,
                Message = "Lấy dashboard quan sát thông báo thành công",
                Data = result
            });
        }

        /// <summary>
        /// Lấy telemetry biometric gần đây của các lượt check-in.
        /// </summary>
        [HttpGet("biometric-telemetry")]
        [Authorize(Roles = "Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<BiometricTelemetryListResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> GetBiometricTelemetry([FromQuery] GetBiometricTelemetryQueryDto query)
        {
            _logger.LogInformation(
                "Yêu cầu lấy biometric telemetry. Page={Page}, Size={Size}, EventId={EventId}, FaceStatus={FaceStatus}",
                query.PageNumber,
                query.PageSize,
                query.EventId,
                query.FaceStatus);

            var result = await _reportingService.GetBiometricTelemetryAsync(query);

            return Ok(new ApiResponseDto<BiometricTelemetryListResponseDto>
            {
                Success = true,
                Message = $"Tìm thấy {result.Telemetry.TotalCount} lượt check-in telemetry",
                Data = result
            });
        }
    }
}


