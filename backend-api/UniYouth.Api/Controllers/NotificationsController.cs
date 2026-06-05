using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Notifications;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// API endpoints quản lý thông báo người dùng.
    /// 
    /// Hệ thống thông báo hỗ trợ:
    /// - Đa thiết bị (Web + Mobile)
    /// - Phân trang để tối ưu hiệu suất
    /// - Đánh dấu đã đọc/chưa đọc
    /// - Lực theo loại và mức để ưu tiên
    /// 
    /// Thông báo tự động được tạo khi:
    /// - Đang ký sự kiện thành công
    /// - Điểm danh thành công/thất bại
    /// - Sự kiện bị cập nhật
    /// </summary>
    [ApiController]
    [Route("api/notifications")]
    [Authorize]
    [Produces("application/json")]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notificationService;
        private readonly INotificationRealtimeDispatcher _notificationRealtimeDispatcher;
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            INotificationService notificationService,
            INotificationRealtimeDispatcher notificationRealtimeDispatcher,
            ILogger<NotificationsController> logger)
        {
            _notificationService = notificationService;
            _notificationRealtimeDispatcher = notificationRealtimeDispatcher;
            _logger = logger;
        }

        /// <summary>
        /// Lấy danh sách thông báo của người dùng hiện tại với phân trang
        /// </summary>
        /// <param name="pageNumber">Số trang (mức động: 1)</param>
        /// <param name="pageSize">Số lượng item trên trang (mức động: 20, tối đa: 100)</param>
        /// <returns>Danh sách thông báo có phân trang</returns>
        /// <response code="200">Trả về danh sách thông báo</response>
        /// <response code="401">Người dùng chưa đăng nhập</response>
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponseDto<NotificationListResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetNotifications(
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 20)
        {
            // Lấy UserID từ JWT token
            var userId = User.GetUserId();

            var result = await _notificationService.GetUserNotificationsAsync(
                userId,
                pageNumber,
                pageSize);

            return Ok(new ApiResponseDto<NotificationListResponseDto>
            {
                Success = true,
                Message = "Lấy danh sách thông báo thành công",
                Data = result
            });
        }

        /// <summary>
        /// Đánh dấu một thông báo là đã đọc
        /// </summary>
        /// <param name="id">ID thông báo</param>
        /// <returns>Kết quả thành công</returns>
        /// <response code="200">Đánh dấu thành công</response>
        /// <response code="404">Không tìm thấy thông báo</response>
        /// <response code="403">Không có quyền truy cập thông báo này</response>
        /// <response code="401">Người dùng chưa đăng nhập</response>
        [HttpPut("{id}/read")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> MarkAsRead([FromRoute] int id)
        {
            // Lấy UserID từ JWT token
            var userId = User.GetUserId();

            var updated = await _notificationService.MarkAsReadAsync(id, userId);

            if (updated)
            {
                await DispatchMarkReadRealtimeAsync(userId, id);

                return Ok(new ApiResponseDto<object>
                {
                    Success = true,
                    Message = "Đánh dấu thông báo là đã đọc"
                });
            }

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Thông báo đã được đánh dấu đã đọc trước đó"
            });
        }

        /// <summary>
        /// Đánh dấu tất cả thông báo của người dùng là đã đọc
        /// </summary>
        /// <returns>Số lượng thông báo đã được đánh dấu</returns>
        /// <response code="200">Đánh dấu thành công</response>
        /// <response code="401">Người dùng chưa đăng nhập</response>
        [HttpPut("read-all")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = User.GetUserId();
            var count = await _notificationService.MarkAllAsReadAsync(userId);

            if (count > 0)
            {
                await DispatchMarkReadAllRealtimeAsync(userId, count);
            }

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = $"Đánh dấu {count} thông báo là đã đọc",
                Data = new { markedCount = count }
            });
        }

        /// <summary>
        /// Lấy số lượng thông báo chưa đọc
        /// Dùng để hiển thị badge/counter trên UI
        /// </summary>
        /// <returns>Số lượng thông báo chưa đọc</returns>
        /// <response code="200">Trả về số lượng chưa đọc</response>
        /// <response code="401">Người dùng chưa đăng nhập</response>
        [HttpGet("unread-count")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = User.GetUserId();
            var count = await _notificationService.GetUnreadCountAsync(userId);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Lấy số lượng thông báo chưa đọc thành công",
                Data = new { unreadCount = count }
            });
        }

        /// <summary>
        /// Helper method: Lấy UserID từ JWT token
        /// </summary>
        private int GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                           ?? User.FindFirst("sub")?.Value
                           ?? User.FindFirst("userId")?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
            {
                _logger.LogError("Không tìm thấy UserID trong JWT token");
                throw new UnauthorizedAccessException("Token không hợp lệ");
            }

            if (!int.TryParse(userIdClaim, out int userId))
            {
                _logger.LogError("UserID trong token không hợp lệ: {UserIdClaim}", userIdClaim);
                throw new UnauthorizedAccessException("Token không hợp lệ");
            }

            return userId;
        }

        private async Task DispatchMarkReadRealtimeAsync(int userId, int notificationId)
        {
            try
            {
                var unreadCount = await _notificationService.GetUnreadCountAsync(userId);
                await _notificationRealtimeDispatcher.DispatchReadAsync(
                    new NotificationReadRealtimePayload(
                        NotificationId: notificationId,
                        UserId: userId,
                        ReadDate: DateTime.Now,
                        UnreadCount: unreadCount),
                    CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Gửi realtime notification_read thất bại (best-effort). NotificationID={NotificationId}, UserID={UserId}",
                    notificationId,
                    userId);
            }
        }

        private async Task DispatchMarkReadAllRealtimeAsync(int userId, int markedCount)
        {
            try
            {
                var unreadCount = await _notificationService.GetUnreadCountAsync(userId);
                await _notificationRealtimeDispatcher.DispatchReadAllAsync(
                    new NotificationReadAllRealtimePayload(
                        UserId: userId,
                        MarkedCount: markedCount,
                        ReadDate: DateTime.Now,
                        UnreadCount: unreadCount),
                    CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Gửi realtime notification_read_all thất bại (best-effort). UserID={UserId}, MarkedCount={MarkedCount}",
                    userId,
                    markedCount);
            }
        }
    }
}

