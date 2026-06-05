using UniYouth.Admin.Models.DTOs.Points;

namespace UniYouth.Admin.Services.Points
{
    public interface IPointsApiService
    {
        Task<UserPointSummaryDto?> GetMyPointsSummaryAsync();
    }
}

