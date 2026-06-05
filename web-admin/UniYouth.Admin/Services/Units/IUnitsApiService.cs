using UniYouth.Admin.Models.DTOs.Units;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Units
{
    public interface IUnitsApiService
    {
        Task<ApiResult<IReadOnlyList<UnitOptionDto>>> GetUnitsAsync(bool activeOnly = true);
    }
}
