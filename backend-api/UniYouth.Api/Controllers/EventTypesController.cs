using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events;
using UniYouth.Api.Shared.Constants;

namespace UniYouth.Api.Controllers
{
    [ApiController]
    [Route("api/event-types")]
    [Authorize]
    [Produces("application/json")]
    public class EventTypesController : ControllerBase
    {
        private readonly IEventTypeService _eventTypeService;
        private readonly ILogger<EventTypesController> _logger;

        public EventTypesController(
            IEventTypeService eventTypeService,
            ILogger<EventTypesController> logger)
        {
            _eventTypeService = eventTypeService;
            _logger = logger;
        }

        /// <summary>
        /// Lấy danh sách loại sự kiện (master data)
        /// - Tất cả user đã đăng nhập đều được xem
        /// </summary>
        [HttpGet]
        [ProducesResponseType(typeof(ApiResponseDto<List<EventTypeDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetEventTypes(CancellationToken cancellationToken)
        {
            var list = await _eventTypeService.GetEventTypesAsync(cancellationToken);

            return Ok(new ApiResponseDto<List<EventTypeDto>>
            {
                Success = true,
                Message = $"Tìm thấy {list.Count} loại sự kiện",
                Data = list
            });
        }

        /// <summary>
        /// Tạo mới loại sự kiện (Admin)
        /// </summary>
        [HttpPost]
        [Authorize(Roles = RoleNames.Admin)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CreateEventType(
            [FromBody] CreateEventTypeRequestDto requestDto,
            CancellationToken cancellationToken)
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

            var typeId = await _eventTypeService.CreateEventTypeAsync(requestDto, cancellationToken);
            _logger.LogInformation("Tạo loại sự kiện thành công. TypeId={TypeId}", typeId);

            return StatusCode(StatusCodes.Status201Created, new ApiResponseDto<object>
            {
                Success = true,
                Message = "Tạo loại sự kiện thành công.",
                Data = new { typeId }
            });
        }

        /// <summary>
        /// Cập nhật loại sự kiện (Admin)
        /// </summary>
        [HttpPut("{typeId:int}")]
        [Authorize(Roles = RoleNames.Admin)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UpdateEventType(
            int typeId,
            [FromBody] UpdateEventTypeRequestDto requestDto,
            CancellationToken cancellationToken)
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

            await _eventTypeService.UpdateEventTypeAsync(typeId, requestDto, cancellationToken);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Cập nhật loại sự kiện thành công."
            });
        }

        /// <summary>
        /// Xoá loại sự kiện (Admin)
        /// - Không cho xoá nếu đang có Event sử dụng
        /// </summary>
        [HttpDelete("{typeId:int}")]
        [Authorize(Roles = RoleNames.Admin)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status409Conflict)]
        public async Task<IActionResult> DeleteEventType(int typeId, CancellationToken cancellationToken)
        {
            await _eventTypeService.DeleteEventTypeAsync(typeId, cancellationToken);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Xoá loại sự kiện thành công."
            });
        }
    }
}


