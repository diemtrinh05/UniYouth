using UniYouth.Admin.Models.DTOs.LocationPresets;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.LocationPresets
{
    public interface ILocationPresetsApiService
    {
        Task<ApiResult<LocationPresetDtoPaginatedResultDto>> GetLocationPresetsAsync(
            int pageNumber = 1,
            int pageSize = 20,
            string? q = null,
            int? instituteId = null,
            bool includeInactive = false);

        Task<ApiResult<LocationPresetDto>> GetByIdAsync(int id);
        Task<ApiResult<LocationPresetDto>> CreateAsync(CreateLocationPresetRequestDto request);
        Task<ApiResult<LocationPresetDto>> UpdateAsync(int id, UpdateLocationPresetRequestDto request);
        Task<ApiResult<bool>> DeleteAsync(int id);
    }
}

