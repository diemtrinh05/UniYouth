using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.NotificationPreferences;
using UniYouth.Api.Shared.Enums;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    [ApiController]
    [Route("api/notification-preferences")]
    [Authorize]
    [Produces("application/json")]
    public sealed class NotificationPreferencesController : ControllerBase
    {
        private readonly INotificationPreferenceService _notificationPreferenceService;

        public NotificationPreferencesController(INotificationPreferenceService notificationPreferenceService)
        {
            _notificationPreferenceService = notificationPreferenceService;
        }

        [HttpGet]
        [ProducesResponseType(typeof(ApiResponseDto<List<NotificationPreferenceDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetMyPreferences(CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var data = await _notificationPreferenceService.GetUserPreferencesAsync(userId, cancellationToken);

            return Ok(new ApiResponseDto<List<NotificationPreferenceDto>>
            {
                Success = true,
                Message = "Lấy danh sách notification preferences thành công",
                Data = data
            });
        }

        [HttpPut("{notificationTypeId:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<NotificationPreferenceDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UpsertPreference(
            [FromRoute] int notificationTypeId,
            [FromBody] UpsertNotificationPreferenceRequestDto dto,
            CancellationToken cancellationToken)
        {
            if (!Enum.IsDefined(typeof(NotificationTypeEnum), notificationTypeId))
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "NotificationTypeID không hợp lệ"
                });
            }

            var userId = User.GetUserId();
            var preference = await _notificationPreferenceService.UpsertPreferenceAsync(
                userId,
                (NotificationTypeEnum)notificationTypeId,
                dto,
                cancellationToken);

            return Ok(new ApiResponseDto<NotificationPreferenceDto>
            {
                Success = true,
                Message = "Cập nhật notification preference thành công",
                Data = preference
            });
        }
    }
}
