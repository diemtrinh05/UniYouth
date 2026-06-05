using UniYouth.Admin.Models.DTOs.EventPoints;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.EventPoints
{
    /// <summary>
    /// Interface cho EventPointsService
    /// Dùng để Dependency Injection
    /// </summary>
    public interface IEventPointsApiService
    {
        Task<ApiResult<List<EventPointDto>>> GetEventPointsAsync(int eventId);
        Task<ApiResult<EventPointDto>> CreateEventPointAsync(int eventId, CreateEventPointRequestDto request);
        Task<ApiResult<EventPointDto>> UpdateEventPointAsync(int eventPointId, UpdateEventPointRequestDto request);
        Task<ApiResult<bool>> DeleteEventPointAsync(int eventPointId);
        Task<ApiResult<EventDetailDto>> GetEventDetailAsync(int eventId);
    }
}
