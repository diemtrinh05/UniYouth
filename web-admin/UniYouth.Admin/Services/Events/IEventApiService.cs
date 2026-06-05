using UniYouth.Admin.Models.DTOs.Events.Requests;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Events
{
    /// <summary>
    /// Interface cho ApiClientService
    /// Dùng cho Dependency Injection
    /// </summary>
    public interface IEventApiService
    {
        // Events
        Task<EventListResponse?> GetEventsAsync(
            int pageNumber = 1,
            int pageSize = 10,
            string? q = null,
            int? eventTypeId = null,
            int? instituteId = null,
            DateTime? startDate = null,
            DateTime? endDate = null,
            string? sortBy = null,
            string? sortDir = null,
            int? status = null);

        Task<EventDetailDto?> GetEventByIdAsync(int eventId);
        Task<ApiResult<EventDetailDto>> CreateEventAsync(CreateEventRequestDto request);
        Task<ApiResult<EventDetailDto>> UpdateEventAsync(int eventId, UpdateEventRequestDto request);
        Task<ApiResult<EventDetailDto>> CancelEventAsync(int eventId, CancelEventRequestDto request);
        Task<ApiResult<EventDetailDto>> CloseEventAsync(int eventId);

    }
}
