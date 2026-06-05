using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Points;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// API quản lý điểm rèn luyện của người dùng
    /// 
    /// PHÂN QUYỀN:
    /// - Tất cả người dùng đăng nhập đều có thể xem điểm của CHÍNH MÌNH
    /// - Không yêu cầu role cả thế nào
    /// 
    /// ENDPOINTS:
    /// - GET /api/users/me/points         : Xem tổng hợp điểm rèn luyện
    /// - GET /api/users/me/points/history : Xem lịch sử cộng / trừ điểm
    /// 
    /// USE CASE:
    /// - Mobile app: hiển thị điểm trên trang hồ sơ cá nhân
    /// - Web app   : dashboard sinh viên
    /// </summary>
    [ApiController]
    [Route("api/users")]
    [Authorize]
    public class PointsController : ControllerBase
    {
        private readonly IActivityPointService _activityPointService;
        private readonly ILogger<PointsController> _logger;

        public PointsController(
            IActivityPointService activityPointService,
            ILogger<PointsController> logger)
        {
            _activityPointService = activityPointService;
            _logger = logger;
        }

        /// <summary>
        /// Lấy tổng hợp điểm rèn luyện của user hiện tại
        /// </summary>
        /// <returns>200 OK với thông tin điểm</returns>
        /// <response code="200">Thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="404">Không tìm thấy user</response>
        [HttpGet("me/points")]
        [ProducesResponseType(typeof(ApiResponseDto<UserPointSummaryDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetMyPoints()
        {
            // ================================================================
            // Lấy USER ID TỪ TOKEN JWT
            // ================================================================
            //var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("Token JWT không hợp lệ hoặc thiếu UserID claim");
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            _logger.LogInformation("User {UserId} đang xem điểm của mình", userId);

            // ================================================================
            // GỌI SERVICE LẤY THÔNG TIN ĐIỂM
            // ================================================================
            var summary = await _activityPointService.GetUserPointSummaryAsync(userId);

            return Ok(new ApiResponseDto<UserPointSummaryDto>
            {
                Success = true,
                Message = "Lấy thông tin điểm thành công",
                Data = summary
            });
        }

        /// <summary>
        /// Lấy lịch sử cộng / trừ điểm chi tiết của user hiện tại
        /// </summary>
        /// <returns>200 OK với danh sách lịch sử</returns>
        /// <response code="200">Thành công</response>
        /// <response code="401">Chưa xác thực</response>
        /// <response code="404">Không tìm thấy user</response>
        [HttpGet("me/points/history")]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<PointHistoryItemDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetMyPointsHistory([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20)
        {
            // LẤY USER ID TỪ TOKEN JWT
            //var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("Token JWT không hợp lệ hoặc thiếu UserID claim");
            //    return Unauthorized(new { message = "Token xác thực không hợp lệ" });
            //}
            var userId = User.GetUserId();
            _logger.LogInformation(
                "User {UserId} đang xem lịch sử cộng / trừ điểm",
                userId);

            // ================================================================
            // LẤY LỊCH SỬ ĐIỂM
            // ================================================================
            const int MaxPageSize = 100;
            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1) pageSize = 20;
            if (pageSize > MaxPageSize) pageSize = MaxPageSize;

            var result = await _activityPointService.GetUserPointHistoryAsync(userId, pageNumber, pageSize);

            return Ok(new ApiResponseDto<PaginatedResultDto<PointHistoryItemDto>>
            {
                Success = true,
                Message = $"Tìm thấy {result.TotalCount} bản ghi lịch sử điểm",
                Data = result
            });
        }
    }
}

