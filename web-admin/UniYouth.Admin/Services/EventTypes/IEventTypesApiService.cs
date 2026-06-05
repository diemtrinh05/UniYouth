using UniYouth.Admin.Models.DTOs.EventTypes;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.EventTypes
{
    public interface IEventTypesApiService
    {
        Task<ApiResult<List<EventTypeDto>>> GetEventTypesAsync();
        Task<ApiResult<string?>> CreateEventTypeAsync(CreateEventTypeRequestDto request);
        Task<ApiResult<string?>> UpdateEventTypeAsync(int typeId, UpdateEventTypeRequestDto request);
        Task<ApiResult<string?>> DeleteEventTypeAsync(int typeId);
    }
}

