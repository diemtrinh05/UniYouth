using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Models.DTOs.QrCodes;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.QrCodes
{
    /// <summary>
    /// Interface cho QrCodesApiService
    /// Dùng để Dependency Injection
    /// </summary>
    public interface IQrCodesApiService
    {
        Task<ApiResult<EventQrListItemDtoPaginatedResultDto>> GetEventQrCodesAsync(
            int eventId,
            int pageNumber = 1,
            int pageSize = 10,
            bool? isActive = null,
            bool? validNow = null);
        Task<ApiResult<EventQrResponseDto>> GenerateQrCodeAsync(
            int eventId,
            GenerateEventQrRequestDto request);
        Task<ApiResult<DeactivateQrResponseDto>> DeactivateQrCodeAsync(int qrId);
        Task<ApiResult<QrCodeDetailResponseDto>> GetQrCodeDetailAsync(int qrId);
        Task<ApiResult<EventDetailDto>> GetEventDetailAsync(int eventId);
    }
}
