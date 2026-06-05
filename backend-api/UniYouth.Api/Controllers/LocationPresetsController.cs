using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Locations;
using UniYouth.Api.Shared.Constants;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    [ApiController]
    [Route("api/admin/location-presets")]
    [Authorize(Roles = RoleNames.CanBo + "," + RoleNames.Admin)]
    [Produces("application/json")]
    public sealed class LocationPresetsController : ControllerBase
    {
        private readonly ILocationPresetService _locationPresetService;

        public LocationPresetsController(ILocationPresetService locationPresetService)
        {
            _locationPresetService = locationPresetService;
        }

        [HttpGet]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<LocationPresetDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> GetPresets(
            [FromQuery] int? instituteId = null,
            [FromQuery] string? q = null,
            [FromQuery] bool includeInactive = false,
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 20,
            CancellationToken cancellationToken = default)
        {
            var requesterUserId = User.GetUserId();
            var isAdmin = User.IsInRole(RoleNames.Admin);

            if (!isAdmin)
            {
                var scopeInstituteId = User.GetInstituteIdOrNull();

                if (!scopeInstituteId.HasValue)
                {
                    return StatusCode(StatusCodes.Status403Forbidden, new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Thiếu claim instituteId để giới hạn phạm vi dữ liệu"
                    });
                }

                instituteId = scopeInstituteId;
            }

            var result = await _locationPresetService.GetPresetsAsync(
                requesterUserId,
                isAdmin,
                instituteId,
                q,
                includeInactive,
                pageNumber,
                pageSize,
                cancellationToken);

            return Ok(new ApiResponseDto<PaginatedResultDto<LocationPresetDto>>
            {
                Success = true,
                Message = "Lấy danh sách vị trí preset thành công",
                Data = result
            });
        }

        [HttpGet("{id:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<LocationPresetDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        public async Task<IActionResult> GetById(int id, CancellationToken cancellationToken)
        {
            var requesterUserId = User.GetUserId();
            var isAdmin = User.IsInRole(RoleNames.Admin);
            int? scopeInstituteId = null;

            if (!isAdmin)
            {
                scopeInstituteId = User.GetInstituteIdOrNull();

                if (!scopeInstituteId.HasValue)
                {
                    return StatusCode(StatusCodes.Status403Forbidden, new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Thiếu claim instituteId để giới hạn phạm vi dữ liệu"
                    });
                }
            }

            var result = await _locationPresetService.GetPresetByIdAsync(requesterUserId, isAdmin, scopeInstituteId, id, cancellationToken);
            return Ok(new ApiResponseDto<LocationPresetDto>
            {
                Success = true,
                Message = "Lấy chi tiết vị trí preset thành công",
                Data = result
            });
        }

        [HttpPost]
        [ProducesResponseType(typeof(ApiResponseDto<LocationPresetDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Create([FromBody] CreateLocationPresetRequestDto dto, CancellationToken cancellationToken)
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

            var requesterUserId = User.GetUserId();
            var isAdmin = User.IsInRole(RoleNames.Admin);
            var scopeInstituteId = isAdmin ? null : User.GetInstituteIdOrNull();

            var result = await _locationPresetService.CreateAsync(requesterUserId, isAdmin, scopeInstituteId, dto, cancellationToken);
            return Ok(new ApiResponseDto<LocationPresetDto>
            {
                Success = true,
                Message = "Tạo vị trí preset thành công",
                Data = result
            });
        }

        [HttpPut("{id:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<LocationPresetDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Update(int id, [FromBody] UpdateLocationPresetRequestDto dto, CancellationToken cancellationToken)
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

            var requesterUserId = User.GetUserId();
            var isAdmin = User.IsInRole(RoleNames.Admin);
            var scopeInstituteId = isAdmin ? null : User.GetInstituteIdOrNull();

            var result = await _locationPresetService.UpdateAsync(requesterUserId, isAdmin, scopeInstituteId, id, dto, cancellationToken);
            return Ok(new ApiResponseDto<LocationPresetDto>
            {
                Success = true,
                Message = "Cập nhật vị trí preset thành công",
                Data = result
            });
        }

        [HttpDelete("{id:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
        {
            var requesterUserId = User.GetUserId();
            var isAdmin = User.IsInRole(RoleNames.Admin);
            var scopeInstituteId = isAdmin ? null : User.GetInstituteIdOrNull();

            await _locationPresetService.DeleteAsync(requesterUserId, isAdmin, scopeInstituteId, id, cancellationToken);
            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Đã xóa vị trí preset"
            });
        }
    }
}
