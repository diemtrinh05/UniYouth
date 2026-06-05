using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Models.DTOs.Registration;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Registration
{
    public interface IRegistrationApiService
    {
        Task<ApiResult<EventRegistrationListResponseDto>> GetEventRegistrationsAsync(
            int eventId,
            int? status = null,
            int pageNumber = 1,
            int pageSize = 20);
        Task<ApiResult<EventDetailDto>> GetEventDetailAsync(int eventId);
    }
}
