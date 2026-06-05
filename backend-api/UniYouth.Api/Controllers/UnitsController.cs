using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Units;

namespace UniYouth.Api.Controllers
{
    [ApiController]
    [Route("api/units")]
    [Authorize]
    [Produces("application/json")]
    public class UnitsController : ControllerBase
    {
        private readonly IUnitLookupService _unitLookupService;

        public UnitsController(IUnitLookupService unitLookupService)
        {
            _unitLookupService = unitLookupService;
        }

        [HttpGet]
        [ProducesResponseType(typeof(ApiResponseDto<IReadOnlyList<UnitOptionDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetUnits([FromQuery] bool activeOnly = true, CancellationToken cancellationToken = default)
        {
            var result = await _unitLookupService.GetUnitsAsync(activeOnly, cancellationToken);
            return Ok(new ApiResponseDto<IReadOnlyList<UnitOptionDto>>
            {
                Success = true,
                Message = "Lấy danh sách đơn vị thành công.",
                Data = result
            });
        }
    }
}

