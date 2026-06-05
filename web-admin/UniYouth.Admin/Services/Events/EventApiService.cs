using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using UniYouth.Admin.Models.DTOs.Events.Requests;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Events
{
    public class EventApiService : ApiClientBase, IEventApiService
    {
        private readonly ILogger<EventApiService> _logger;

        public EventApiService(
            HttpClient httpClient,
            IHttpContextAccessor accessor,
            ILogger<EventApiService> logger,
            IConfiguration configuration)
            : base(httpClient, accessor)
        {
            _logger = logger;

            // Cấu hình HttpClient
            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException("API Base URL chưa được cấu hình");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));
        }

        #region Events APIs
        /// <summary>
        /// Lấy danh sách events từ API
        /// Endpoint: GET /api/Events/admin
        /// </summary>
        public async Task<EventListResponse?> GetEventsAsync(
            int pageNumber = 1,
            int pageSize = 10,
            string? q = null,
            int? eventTypeId = null,
            int? instituteId = null,
            DateTime? startDate = null,
            DateTime? endDate = null,
            string? sortBy = null,
            string? sortDir = null,
            int? status = null)
        {
            try
            {
                // swagger_v2.json: GET /api/Events/admin hỗ trợ paging + filter + sort
                var query = new Dictionary<string, string?>
                {
                    ["pageNumber"] = (pageNumber <= 0 ? 1 : pageNumber).ToString(),
                    ["pageSize"] = (pageSize <= 0 ? 10 : pageSize).ToString()
                };

                if (status.HasValue)
                {
                    query["status"] = status.Value.ToString();
                }

                if (!string.IsNullOrWhiteSpace(q))
                {
                    query["q"] = q;
                }

                if (eventTypeId.HasValue)
                {
                    query["eventTypeId"] = eventTypeId.Value.ToString();
                }

                if (instituteId.HasValue)
                {
                    query["instituteId"] = instituteId.Value.ToString();
                }

                if (startDate.HasValue)
                {
                    query["startFrom"] = startDate.Value.ToString("O");
                }

                if (endDate.HasValue)
                {
                    query["startTo"] = endDate.Value.ToString("O");
                }

                if (!string.IsNullOrWhiteSpace(sortBy))
                {
                    query["sortBy"] = sortBy;
                }

                if (!string.IsNullOrWhiteSpace(sortDir))
                {
                    query["sortDir"] = sortDir;
                }

                var endpoint = QueryHelpers.AddQueryString("/api/Events/admin", query);

                _logger.LogInformation("Calling API: GET {Endpoint}", endpoint);

                // Thêm JWT token vào header Authorization
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync(endpoint);

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể tải danh sách sự kiện");
                    _logger.LogWarning(
                        "API returned error: {StatusCode}. Message: {Message}",
                        response.StatusCode,
                        message);
                    return null;
                }

                var content = await response.Content.ReadAsStringAsync();

                // Backend thực tế có thể trả 1 trong 2 dạng:
                // A) Swagger: EventListItemDtoPaginatedResultDto (không wrapper)
                // B) API_DOCUMENTATION.md: ApiResponseDto<EventListItemDtoPaginatedResultDto>
                //
                // Không suy đoán: thử parse wrapper trước, nếu fail thì fallback parse direct.
                try
                {
                    var wrapped = JsonSerializer.Deserialize<ApiResponseDto<EventListResponse>>(
                        content,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                    if (wrapped != null)
                    {
                        if (wrapped.Success == true && wrapped.Data != null)
                        {
                            _logger.LogInformation(
                                "Successfully retrieved {Count} events (wrapper)",
                                wrapped.Data.Items?.Count ?? 0);
                            return wrapped.Data;
                        }

                        _logger.LogWarning(
                            "Events list API returned success=false or data=null. Message: {Message}",
                            wrapped.Message);
                        return null;
                    }
                }
                catch (JsonException)
                {
                    // ignore and fallback to direct parsing below
                }

                var direct = JsonSerializer.Deserialize<EventListResponse>(
                    content,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                _logger.LogInformation(
                    "Successfully retrieved {Count} events (direct)",
                    direct?.Items?.Count ?? 0);

                return direct;
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "HTTP request error when calling Events API");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error when calling Events API");
                return null;
            }
        }

        /// <summary>
        /// GET /api/Events/{id} - Lấy chi tiết một event
        /// </summary>
        public async Task<EventDetailDto?> GetEventByIdAsync(int eventId)
        {
            try
            {
                var endpoint = $"/api/Events/{eventId}";

                _logger.LogInformation("Calling API: GET {Endpoint}", endpoint);

                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync(endpoint);

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    _logger.LogWarning("Event {EventId} not found", eventId);
                    return null;
                }

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("API returned error: {StatusCode}", response.StatusCode);
                    return null;
                }

                ApiResponseDto<EventDetailDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<EventDetailDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Failed to parse EventDetailDtoApiResponseDto for event {EventId}", eventId);
                    return null;
                }

                if (apiResponse == null)
                {
                    _logger.LogWarning("Empty body when retrieving event {EventId}", eventId);
                    return null;
                }

                if (!apiResponse.Success || apiResponse.Data == null)
                {
                    _logger.LogWarning(
                        "Event detail API returned success=false or data=null for event {EventId}. Message: {Message}",
                        eventId,
                        apiResponse.Message);
                    return null;
                }

                return apiResponse.Data;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting event {EventId}", eventId);
                return null;
            }
        }

        /// <summary>
        /// POST /api/Events - Tạo event mới
        /// </summary>
        public async Task<ApiResult<EventDetailDto>> CreateEventAsync(CreateEventRequestDto request)
        {
            try
            {
                var endpoint = "/api/Events";

                _logger.LogInformation("Calling API: POST {Endpoint}", endpoint);

                AddAuthorizationHeader();

                var jsonContent = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync(endpoint, content);

                var responseContent = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventDetailDto>? apiResponse;
                    try
                    {
                        apiResponse = JsonSerializer.Deserialize<ApiResponseDto<EventDetailDto>>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Failed to parse EventDetailDtoApiResponseDto when creating event");
                        return new ApiResult<EventDetailDto>
                        {
                            Success = false,
                            ErrorMessage = "Lỗi xử lý dữ liệu từ server."
                        };
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        _logger.LogInformation("Event created successfully: {EventId}", apiResponse.Data.EventId);

                        return new ApiResult<EventDetailDto>
                        {
                            Success = true,
                            Data = apiResponse.Data
                        };
                    }

                    return new ApiResult<EventDetailDto>
                    {
                        Success = false,
                        ErrorMessage = ApiErrorReader.BuildErrorMessage(
                            apiResponse?.Message ?? "Không thể tạo sự kiện",
                            apiResponse?.Errors)
                    };
                }
                else
                {
                    _logger.LogWarning("Failed to create event. Status: {StatusCode}", response.StatusCode);
                    var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể tạo sự kiện");

                    return new ApiResult<EventDetailDto>
                    {
                        Success = false,
                        ErrorMessage = errorMessage
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating event");
                return new ApiResult<EventDetailDto>
                {
                    Success = false,
                    ErrorMessage = "Đã có lỗi xảy ra khi tạo sự kiện"
                };
            }
        }

        /// <summary>
        /// PUT /api/Events/{id} - Cập nhật event
        /// </summary>
        public async Task<ApiResult<EventDetailDto>> UpdateEventAsync(int eventId, UpdateEventRequestDto request)
        {
            try
            {
                var endpoint = $"/api/Events/{eventId}";

                _logger.LogInformation("Calling API: PUT {Endpoint}", endpoint);

                AddAuthorizationHeader();

                var jsonContent = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await _httpClient.PutAsync(endpoint, content);

                var responseContent = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventDetailDto>? apiResponse;
                    try
                    {
                        apiResponse = JsonSerializer.Deserialize<ApiResponseDto<EventDetailDto>>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Failed to parse EventDetailDtoApiResponseDto when updating event {EventId}", eventId);
                        return new ApiResult<EventDetailDto>
                        {
                            Success = false,
                            ErrorMessage = "Lỗi xử lý dữ liệu từ server."
                        };
                    };

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        _logger.LogInformation("Event updated successfully: {EventId}", eventId);

                        return new ApiResult<EventDetailDto>
                        {
                            Success = true,
                            Data = apiResponse.Data
                        };
                    }

                    return new ApiResult<EventDetailDto>
                    {
                        Success = false,
                        ErrorMessage = ApiErrorReader.BuildErrorMessage(
                            apiResponse?.Message ?? "Không thể cập nhật sự kiện",
                            apiResponse?.Errors)
                    };
                }
                else
                {
                    _logger.LogWarning("Failed to update event {EventId}. Status: {StatusCode}", eventId, response.StatusCode);
                    var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể cập nhật sự kiện");

                    return new ApiResult<EventDetailDto>
                    {
                        Success = false,
                        ErrorMessage = errorMessage
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating event {EventId}", eventId);
                return new ApiResult<EventDetailDto>
                {
                    Success = false,
                    ErrorMessage = "Đã có lỗi xảy ra khi cập nhật sự kiện"
                };
            }
        }

        /// <summary>
        /// PUT /api/Events/{id}/cancel - Hủy sự kiện
        /// </summary>
        public async Task<ApiResult<EventDetailDto>> CancelEventAsync(int eventId, CancelEventRequestDto request)
        {
            try
            {
                var endpoint = $"/api/Events/{eventId}/cancel";

                _logger.LogInformation("Calling API: PUT {Endpoint}", endpoint);

                AddAuthorizationHeader();

                var jsonContent = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");
                var response = await _httpClient.PutAsync(endpoint, content);

                var responseContent = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    // Swagger: trả EventDetailDto (không wrapper)
                    // API_DOCUMENTATION.md: có thể trả wrapper ApiResponseDto<EventDetailDto>
                    try
                    {
                        var wrapped = JsonSerializer.Deserialize<ApiResponseDto<EventDetailDto>>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                        if (wrapped?.Success == true && wrapped.Data != null)
                        {
                            return ApiResult<EventDetailDto>.SuccessResult(wrapped.Data);
                        }
                    }
                    catch (JsonException)
                    {
                        // ignore and fallback to direct parsing below
                    }

                    try
                    {
                        var direct = JsonSerializer.Deserialize<EventDetailDto>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                        if (direct != null)
                        {
                            return ApiResult<EventDetailDto>.SuccessResult(direct);
                        }
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Failed to parse EventDetailDto when cancelling event {EventId}", eventId);
                        return ApiResult<EventDetailDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    return ApiResult<EventDetailDto>.FailureResult("Không thể hủy sự kiện.");
                }

                var defaultMessage = response.StatusCode switch
                {
                    System.Net.HttpStatusCode.NotFound => "Không tìm thấy sự kiện.",
                    System.Net.HttpStatusCode.Forbidden => "Bạn không có quyền hủy sự kiện này.",
                    System.Net.HttpStatusCode.Unauthorized => "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.",
                    _ => "Không thể hủy sự kiện."
                };

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(response, defaultMessage);
                _logger.LogWarning(
                    "Cancel event failed. Status: {Status}. Message: {Message}. Body: {Body}",
                    response.StatusCode,
                    errorMessage,
                    responseContent);

                return ApiResult<EventDetailDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error cancelling event {EventId}", eventId);
                return ApiResult<EventDetailDto>.FailureResult("Đã xảy ra lỗi khi hủy sự kiện.");
            }
        }

        /// <summary>
        /// PUT /api/Events/{id}/close - Kết thúc sự kiện
        /// swagger_v3.json: response 200 trả EventDetailDto (không wrapper).
        /// </summary>
        public async Task<ApiResult<EventDetailDto>> CloseEventAsync(int eventId)
        {
            try
            {
                var endpoint = $"/api/Events/{eventId}/close";

                _logger.LogInformation("Calling API: PUT {Endpoint}", endpoint);

                AddAuthorizationHeader();

                using var req = new HttpRequestMessage(HttpMethod.Put, endpoint);
                var response = await _httpClient.SendAsync(req);

                var responseContent = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    // Try wrapper first (ApiResponseDto<EventDetailDto>), then fallback to direct DTO.
                    try
                    {
                        var wrapped = JsonSerializer.Deserialize<ApiResponseDto<EventDetailDto>>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                        if (wrapped?.Success == true && wrapped.Data != null)
                        {
                            return ApiResult<EventDetailDto>.SuccessResult(wrapped.Data);
                        }
                    }
                    catch (JsonException)
                    {
                        // ignore and fallback below
                    }

                    try
                    {
                        var direct = JsonSerializer.Deserialize<EventDetailDto>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                        if (direct != null)
                        {
                            return ApiResult<EventDetailDto>.SuccessResult(direct);
                        }
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Failed to parse EventDetailDto when closing event {EventId}", eventId);
                        return ApiResult<EventDetailDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    return ApiResult<EventDetailDto>.FailureResult("Không thể kết thúc sự kiện.");
                }

                var defaultMessage = response.StatusCode switch
                {
                    System.Net.HttpStatusCode.BadRequest => "Không thể kết thúc sự kiện.",
                    System.Net.HttpStatusCode.NotFound => "Không tìm thấy sự kiện.",
                    System.Net.HttpStatusCode.Forbidden => "Bạn không có quyền kết thúc sự kiện này.",
                    System.Net.HttpStatusCode.Unauthorized => "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.",
                    _ => "Không thể kết thúc sự kiện."
                };

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(response, defaultMessage);
                _logger.LogWarning(
                    "Close event failed. Status: {Status}. Message: {Message}. Body: {Body}",
                    response.StatusCode,
                    errorMessage,
                    responseContent);

                return ApiResult<EventDetailDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error closing event {EventId}", eventId);
                return ApiResult<EventDetailDto>.FailureResult("Đã xảy ra lỗi khi kết thúc sự kiện.");
            }
        }

        #endregion
    }
}
