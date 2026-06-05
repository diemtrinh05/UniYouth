using System.Text;
using System.Text.Json;
using UniYouth.Admin.Models.DTOs.EventTypes;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.EventTypes
{
    public class EventTypesApiService : ApiClientBase, IEventTypesApiService
    {
        private readonly ILogger<EventTypesApiService> _logger;

        public EventTypesApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<EventTypesApiService> logger,
            IConfiguration configuration)
            : base(httpClient, httpContextAccessor)
        {
            _logger = logger;

            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException("API Base URL chưa được cấu hình");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }

        public async Task<ApiResult<List<EventTypeDto>>> GetEventTypesAsync()
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync("/api/event-types");
                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể tải danh sách loại sự kiện");
                    return ApiResult<List<EventTypeDto>>.FailureResult(message);
                }

                ApiResponseDto<List<EventTypeDto>>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<List<EventTypeDto>>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse EventTypeDtoListApiResponseDto");
                    return ApiResult<List<EventTypeDto>>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<List<EventTypeDto>>.SuccessResult(apiResponse.Data, apiResponse.Message ?? "");
                }

                var errorMessage = ApiErrorReader.BuildErrorMessage(
                    apiResponse?.Message ?? "Không thể tải danh sách loại sự kiện",
                    apiResponse?.Errors);
                return ApiResult<List<EventTypeDto>>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải danh sách loại sự kiện");
                return ApiResult<List<EventTypeDto>>.FailureResult("Đã có lỗi xảy ra khi tải danh sách loại sự kiện");
            }
        }

        public async Task<ApiResult<string?>> CreateEventTypeAsync(CreateEventTypeRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("/api/event-types", content);

                return await ReadObjectApiResponseAsync(response, "Không thể tạo loại sự kiện");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tạo loại sự kiện");
                return ApiResult<string?>.FailureResult("Đã có lỗi xảy ra khi tạo loại sự kiện");
            }
        }

        public async Task<ApiResult<string?>> UpdateEventTypeAsync(int typeId, UpdateEventTypeRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PutAsync($"/api/event-types/{typeId}", content);

                return await ReadObjectApiResponseAsync(response, "Không thể cập nhật loại sự kiện");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật loại sự kiện typeId={TypeId}", typeId);
                return ApiResult<string?>.FailureResult("Đã có lỗi xảy ra khi cập nhật loại sự kiện");
            }
        }

        public async Task<ApiResult<string?>> DeleteEventTypeAsync(int typeId)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.DeleteAsync($"/api/event-types/{typeId}");
                return await ReadObjectApiResponseAsync(response, "Không thể xóa loại sự kiện");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi xóa loại sự kiện typeId={TypeId}", typeId);
                return ApiResult<string?>.FailureResult("Đã có lỗi xảy ra khi xóa loại sự kiện");
            }
        }

        private async Task<ApiResult<string?>> ReadObjectApiResponseAsync(
            HttpResponseMessage response,
            string defaultErrorMessage)
        {
            if (response.IsSuccessStatusCode)
            {
                ApiResponseDto? api;
                try
                {
                    api = await ApiResponseReader.ReadUntypedAsync(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse ObjectApiResponseDto");
                    return ApiResult<string?>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (api?.Success == true)
                {
                    var rawData = api.Data.HasValue ? api.Data.Value.GetRawText() : null;
                    return ApiResult<string?>.SuccessResult(rawData, api.Message ?? "");
                }

                var message = ApiErrorReader.BuildErrorMessage(
                    api?.Message ?? defaultErrorMessage,
                    api?.Errors);
                return ApiResult<string?>.FailureResult(message);
            }

            var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(response, defaultErrorMessage);
            return ApiResult<string?>.FailureResult(errorMessage);
        }
    }
}

