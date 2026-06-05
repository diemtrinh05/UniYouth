using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using UniYouth.Admin.Models.DTOs.EventImages;
using UniYouth.Admin.Models.ViewModels.EventImages;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;
using UniYouth.Admin.Services.Events;

namespace UniYouth.Admin.Services.EventImages
{
    /// <summary>
    /// Service xử lý các thao tác liên quan đến hình ảnh sự kiện
    /// Kế thừa từ ApiClientBase để sử dụng authentication header
    /// </summary>
    public class EventImagesApiService : ApiClientBase, IEventImagesApiService
    {
        private readonly ILogger<EventImagesApiService> _logger;
        private readonly IConfiguration _configuration;

        public EventImagesApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<EventImagesApiService> logger,
            IConfiguration configuration)
            : base(httpClient, httpContextAccessor)
        {
            _logger = logger;
            _configuration = configuration;

            // Cấu hình HttpClient
            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException("API Base URL không được cấu hình trong appsettings.json");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(60); // Timeout dài hơn cho upload file
        }

        /// <summary>
        /// Lấy danh sách hình ảnh của sự kiện
        /// GET: /api/events/{eventId}/images
        /// </summary>
        public async Task<ApiResult<List<EventImagesDto>>> GetEventImagesAsync(int eventId)
        {
            try
            {
                _logger.LogInformation("Đang lấy danh sách hình ảnh cho sự kiện {EventId}", eventId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/events/{eventId}/images");

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<List<EventImagesDto>>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<List<EventImagesDto>>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse EventImagesDtoListApiResponseDto cho event {EventId}", eventId);
                        return ApiResult<List<EventImagesDto>>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true)
                    {
                        return ApiResult<List<EventImagesDto>>.SuccessResult(apiResponse.Data ?? new List<EventImagesDto>());
                    }

                    return ApiResult<List<EventImagesDto>>.FailureResult(
                        apiResponse?.Message ?? "Không thể tải danh sách hình ảnh");
                }

                _logger.LogWarning("Không thể lấy hình ảnh. Status: {Status}", response.StatusCode);
                return ApiResult<List<EventImagesDto>>.FailureResult(
                    "Không thể tải danh sách hình ảnh");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách hình ảnh cho sự kiện {EventId}", eventId);
                return ApiResult<List<EventImagesDto>>.FailureResult(
                    "Đã xảy ra lỗi khi tải hình ảnh");
            }
        }

        /// <summary>
        /// Upload hình ảnh mới cho sự kiện
        /// POST: /api/events/{eventId}/images
        /// </summary>
        public async Task<ApiResult<UploadEventImageResponseDto>> UploadImagesAsync(
            int eventId,
            IFormFile[] files,
            string imageType,
            string? caption)
        {
            try
            {
                _logger.LogInformation(
                    "Đang upload {Count} hình ảnh cho sự kiện {EventId}",
                    files.Length,
                    eventId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                // Tạo multipart/form-data content
                using var content = new MultipartFormDataContent();

                // Thêm các file
                foreach (var file in files)
                {
                    var fileContent = new StreamContent(file.OpenReadStream());
                    fileContent.Headers.ContentType = new MediaTypeHeaderValue(file.ContentType);
                    content.Add(fileContent, "files", file.FileName);
                }

                // Thêm imageType
                content.Add(new StringContent(imageType), "imageType");

                // Thêm caption nếu có
                if (!string.IsNullOrWhiteSpace(caption))
                {
                    content.Add(new StringContent(caption), "caption");
                }

                var response = await _httpClient.PostAsync(
                    $"api/events/{eventId}/images",
                    content);

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<UploadEventImageResponseDto>? apiResponse;
                    try
                    {
                        // Swagger: POST /api/events/{eventId}/images trả UploadEventImageResponseDtoApiResponseDto (wrapper), status 201
                        apiResponse = await ApiResponseReader.ReadAsync<UploadEventImageResponseDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse UploadEventImageResponseDtoApiResponseDto cho event {EventId}", eventId);
                        return ApiResult<UploadEventImageResponseDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        _logger.LogInformation("Upload thành công {Count} hình ảnh", apiResponse.Data.UploadedCount);
                        return ApiResult<UploadEventImageResponseDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<UploadEventImageResponseDto>.FailureResult(
                        apiResponse?.Message ?? "Không thể tải lên hình ảnh. Vui lòng thử lại.");
                }

                var errorContent = await response.Content.ReadAsStringAsync();
                _logger.LogWarning(
                    "Upload thất bại. Status: {Status}, Error: {Error}",
                    response.StatusCode,
                    errorContent);

                return ApiResult<UploadEventImageResponseDto>.FailureResult(
                    "Không thể tải lên hình ảnh. Vui lòng thử lại.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi upload hình ảnh cho sự kiện {EventId}", eventId);
                return ApiResult<UploadEventImageResponseDto>.FailureResult(
                    "Đã xảy ra lỗi khi tải lên hình ảnh");
            }
        }

        /// <summary>
        /// Xóa hình ảnh
        /// DELETE: /api/events/images/{imageId}
        /// </summary>
        public async Task<ApiResult<bool>> DeleteImageAsync(int imageId)
        {
            try
            {
                _logger.LogInformation("Đang xóa hình ảnh {ImageId}", imageId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var response = await _httpClient.DeleteAsync($"api/events/images/{imageId}");

                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Xóa hình ảnh {ImageId} thành công", imageId);
                    return ApiResult<bool>.SuccessResult(true);
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<bool>.FailureResult("Không tìm thấy hình ảnh");
                }

                if (response.StatusCode == System.Net.HttpStatusCode.Forbidden)
                {
                    return ApiResult<bool>.FailureResult(
                        "Bạn không có quyền xóa hình ảnh này");
                }

                return ApiResult<bool>.FailureResult("Không thể xóa hình ảnh");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi xóa hình ảnh {ImageId}", imageId);
                return ApiResult<bool>.FailureResult(
                    "Đã xảy ra lỗi khi xóa hình ảnh");
            }
        }

        public async Task<ApiResult<bool>> UpdateImageOrderAsync(int imageId, int displayOrder)
        {
            try
            {
                _logger.LogInformation(
                    "Đang cập nhật display order cho image {ImageId} -> {Order}",
                    imageId,
                    displayOrder);

                AddAuthorizationHeader();

                var dto = new UpdateEventImageOrderDto
                {
                    DisplayOrder = displayOrder
                };

                var json = JsonSerializer.Serialize(dto);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await _httpClient.PutAsync(
                    $"api/events/images/{imageId}/order",
                    content);

                if (response.IsSuccessStatusCode)
                {
                    return ApiResult<bool>.SuccessResult(true);
                }

                if (response.StatusCode == HttpStatusCode.NotFound)
                {
                    return ApiResult<bool>.FailureResult("Không tìm thấy hình ảnh");
                }

                return ApiResult<bool>.FailureResult("Không thể cập nhật thứ tự hiển thị");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Lỗi khi cập nhật display order cho image {ImageId}",
                    imageId);

                return ApiResult<bool>.FailureResult(
                    "Đã xảy ra lỗi khi cập nhật thứ tự hiển thị");
            }
        }

        public async Task<ApiResult<EventImagesDto>> UpdateImageMetadataAsync(
            int imageId,
            UpdateEventImageRequestDto request)
        {
            try
            {
                _logger.LogInformation(
                    "Đang cập nhật metadata cho image {ImageId}",
                    imageId);

                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await _httpClient.PutAsync(
                    $"api/events/images/{imageId}",
                    content);

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventImagesDto>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<EventImagesDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse EventImagesDtoApiResponseDto cho image {ImageId}", imageId);
                        return ApiResult<EventImagesDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        return ApiResult<EventImagesDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<EventImagesDto>.FailureResult(
                        apiResponse?.Message ?? "Không thể cập nhật hình ảnh");
                }

                if (response.StatusCode == HttpStatusCode.NotFound)
                {
                    return ApiResult<EventImagesDto>.FailureResult("Không tìm thấy hình ảnh");
                }

                if (response.StatusCode == HttpStatusCode.Forbidden)
                {
                    return ApiResult<EventImagesDto>.FailureResult("Bạn không có quyền cập nhật hình ảnh này");
                }

                return ApiResult<EventImagesDto>.FailureResult("Không thể cập nhật hình ảnh");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật metadata cho image {ImageId}", imageId);
                return ApiResult<EventImagesDto>.FailureResult("Đã xảy ra lỗi khi cập nhật hình ảnh");
            }
        }


        /// <summary>
        /// Lấy thông tin chi tiết sự kiện
        /// GET: /api/Events/{eventId}
        /// </summary>
        public async Task<ApiResult<EventDetailDto>> GetEventDetailAsync(int eventId)
        {
            try
            {
                _logger.LogInformation("Đang lấy thông tin sự kiện {EventId}", eventId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/Events/{eventId}");

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventDetailDto>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<EventDetailDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse EventDetailDtoApiResponseDto cho event {EventId}", eventId);
                        return ApiResult<EventDetailDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        return ApiResult<EventDetailDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<EventDetailDto>.FailureResult(
                        apiResponse?.Message ?? "Không thể tải thông tin sự kiện");
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventDetailDto>.FailureResult("Không tìm thấy sự kiện");
                }

                return ApiResult<EventDetailDto>.FailureResult(
                    "Không thể tải thông tin sự kiện");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy thông tin sự kiện {EventId}", eventId);
                return ApiResult<EventDetailDto>.FailureResult(
                    "Đã xảy ra lỗi khi tải thông tin sự kiện");
            }
        }
    }
}
