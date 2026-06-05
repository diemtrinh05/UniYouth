using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events.Points;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// API endpoints quản lý cấu hình điểm sự kiện.
    ///
    /// Điểm sự kiện xác định số điểm rèn luyện mà người dùng nhận được dựa trên vai trò trong sự kiện.
    /// Cho phép chiến lược phân bổ điểm linh hoạt mà không cần sửa code.
    /// 
    /// Ví dụ các trường hợp sử dụng:
    /// - Sự kiện lớn: Ban tổ chức=50 điểm, Người tham gia=15 điểm, Tình nguyện viên=25 điểm
    /// - Sự kiện nhỏ: Ban tổ chức=20 điểm, Người tham gia=5 điểm, Tình nguyện viên=10 điểm
    /// - Chiến dịch đặc biệt: Tình nguyện viên=50 điểm (để khuyến khích tinh thần tình nguyện)
    /// </summary>
    [ApiController]
    [Route("api/events")]
    [Produces("application/json")]
    public class EventPointsController : ControllerBase
    {
        private readonly IEventPointService _eventPointService;
        private readonly ILogger<EventPointsController> _logger;

        public EventPointsController(
            IEventPointService eventPointService,
            ILogger<EventPointsController> logger)
        {
            _eventPointService = eventPointService;
            _logger = logger;
        }

        /// <summary>
        /// Lấy tất cả cấu hình điểm cho một sự kiện cụ thể
        /// </summary>
        /// <param name="eventId">Mã sự kiện</param>
        /// <returns>Danh sách cấu hình điểm sự kiện</returns>
        /// <response code="200">Trả về danh sách cấu hình điểm</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        [HttpGet("{eventId}/points")]
        [Authorize]
        [ProducesResponseType(typeof(ApiResponseDto<IEnumerable<EventPointDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetEventPoints([FromRoute] int eventId)
        {
            var eventPoints = await _eventPointService.GetEventPointsAsync(eventId);
            return Ok(new ApiResponseDto<IEnumerable<EventPointDto>>
            {
                Success = true,
                Message = "Lấy danh sách cấu hình điểm thành công",
                Data = eventPoints
            });
        }

        /// <summary>
        /// Tạo cấu hình điểm mới cho một sự kiện
        /// </summary>
        /// <param name="eventId">Mã sự kiện</param>
        /// <param name="request">Chi tiết cấu hình điểm</param>
        /// <returns>Cấu hình điểm được tạo</returns>
        /// <response code="201">Tạo cấu hình điểm thành công</response>
        /// <response code="400">Request không hợp lệ hoặc cấu hình trùng lặp</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        /// <response code="403">Người dùng không có quyền</response>
        [HttpPost("{eventId}/points")]
        [Authorize(Roles = "CanBo,Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<EventPointDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> CreateEventPoint(
            [FromRoute] int eventId,
            [FromBody] CreateEventPointRequestDto request)
        {
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

            var actorUserId = User.GetUserId();
            var eventPoint = await _eventPointService.CreateEventPointAsync(eventId, request, actorUserId);

            return CreatedAtAction(
                nameof(GetEventPoints),
                new { eventId },
                new ApiResponseDto<EventPointDto>
                {
                    Success = true,
                    Message = "Tạo cấu hình điểm thành công",
                    Data = eventPoint
                });
        }

        /// <summary>
        /// Cập nhật cấu hình điểm hiện có
        /// </summary>
        /// <param name="eventPointId">Mã cấu hình điểm</param>
        /// <param name="request">Chi tiết cấu hình điểm được cập nhật</param>
        /// <returns>Cấu hình điểm được cập nhật</returns>
        /// <response code="200">Cập nhật cấu hình điểm thành công</response>
        /// <response code="400">Request không hợp lệ</response>
        /// <response code="404">Không tìm thấy cấu hình điểm</response>
        /// <response code="403">Người dùng không có quyền</response>
        [HttpPut("points/{eventPointId}")]
        [Authorize(Roles = "CanBo,Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<EventPointDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> UpdateEventPoint(
            [FromRoute] int eventPointId,
            [FromBody] UpdateEventPointRequestDto request)
        {
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

            var actorUserId = User.GetUserId();
            var eventPoint = await _eventPointService.UpdateEventPointAsync(eventPointId, request, actorUserId);

            return Ok(new ApiResponseDto<EventPointDto>
            {
                Success = true,
                Message = "Cập nhật cấu hình điểm thành công",
                Data = eventPoint
            });
        }

        /// <summary>
        /// Xóa cấu hình điểm
        /// </summary>
        /// <param name="eventPointId">Mã cấu hình điểm</param>
        /// <returns>Trạng thái thành công</returns>
        /// <response code="200">Xóa cấu hình điểm thành công</response>
        /// <response code="400">Không thể xóa vì cấu hình đang được sử dụng</response>
        /// <response code="404">Không tìm thấy cấu hình điểm</response>
        /// <response code="403">Người dùng không có quyền</response>
        [HttpDelete("points/{eventPointId}")]
        [Authorize(Roles = "CanBo,Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> DeleteEventPoint([FromRoute] int eventPointId)
        {
            var actorUserId = User.GetUserId();
            await _eventPointService.DeleteEventPointAsync(eventPointId, actorUserId);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Xóa cấu hình điểm thành công"
            });
        }
    }
}

