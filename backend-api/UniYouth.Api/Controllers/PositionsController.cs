using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Positions;

namespace UniYouth.Api.Controllers
{
    [ApiController]
    [Route("api/positions")]
    [Authorize]
    [Produces("application/json")]
    public class PositionsController : ControllerBase
    {
        private readonly IPositionLookupService _positionLookupService;

        public PositionsController(IPositionLookupService positionLookupService)
        {
            _positionLookupService = positionLookupService;
        }

        [HttpGet]
        [ProducesResponseType(typeof(ApiResponseDto<IReadOnlyList<PositionOptionDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetPositions([FromQuery] bool activeOnly = true, CancellationToken cancellationToken = default)
        {
            var result = await _positionLookupService.GetPositionsAsync(activeOnly, cancellationToken);
            return Ok(new ApiResponseDto<IReadOnlyList<PositionOptionDto>>
            {
                Success = true,
                Message = "Lấy danh sách chức vụ thành công.",
                Data = result
            });
        }
    }
}
