using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.DeviceTokens;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    [ApiController]
    [Route("api/device-tokens")]
    [Authorize]
    [Produces("application/json")]
    public sealed class DeviceTokensController : ControllerBase
    {
        private readonly IDeviceTokenService _deviceTokenService;

        public DeviceTokensController(IDeviceTokenService deviceTokenService)
        {
            _deviceTokenService = deviceTokenService;
        }

        [HttpPost]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Register([FromBody] RegisterDeviceTokenRequestDto dto, CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            await _deviceTokenService.RegisterAsync(userId, dto, cancellationToken);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Đăng ký device token thành công"
            });
        }

        [HttpDelete]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Unregister([FromBody] UnregisterDeviceTokenRequestDto dto, CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            await _deviceTokenService.UnregisterAsync(userId, dto, cancellationToken);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Hủy device token thành công"
            });
        }
    }
}

