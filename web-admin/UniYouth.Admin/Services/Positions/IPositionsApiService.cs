using UniYouth.Admin.Models.DTOs.Positions;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Positions
{
    public interface IPositionsApiService
    {
        Task<ApiResult<IReadOnlyList<PositionOptionDto>>> GetPositionsAsync(bool activeOnly = true);
    }
}
