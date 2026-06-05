using UniYouth.Admin.Models.DTOs.EventImages;
using UniYouth.Admin.Models.ViewModels.EventImages;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.EventImages
{
    /// <summary>
    /// Interface cho EventImagesService
    /// Dùng để Dependency Injection
    /// </summary>
    public interface IEventImagesApiService
    {
        Task<ApiResult<List<EventImagesDto>>> GetEventImagesAsync(int eventId);
        Task<ApiResult<UploadEventImageResponseDto>> UploadImagesAsync(
            int eventId,
            IFormFile[] files,
            string imageType,
            string? caption);
        Task<ApiResult<bool>> DeleteImageAsync(int imageId);
        Task<ApiResult<EventDetailDto>> GetEventDetailAsync(int eventId);
        Task<ApiResult<bool>> UpdateImageOrderAsync(int imageId, int displayOrder);
        Task<ApiResult<EventImagesDto>> UpdateImageMetadataAsync(int imageId, UpdateEventImageRequestDto request);
    }
}
