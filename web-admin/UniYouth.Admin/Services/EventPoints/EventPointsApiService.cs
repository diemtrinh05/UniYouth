using System.Net.Http;
using System.Text;
using System.Text.Json;
using UniYouth.Admin.Models.DTOs.EventPoints;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.EventPoints
{
    /// <summary>
    /// Service xử lý các thao tác liên quan đến Event Points
    /// Kế thừa từ ApiClientBase để tự động xử lý JWT token
    /// </summary>
    public class EventPointsApiService : ApiClientBase, IEventPointsApiService
    {
        private readonly ILogger<EventPointsApiService> _logger;
        private readonly IConfiguration _configuration;

        public EventPointsApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<EventPointsApiService> logger,
            IConfiguration configuration)
            : base(httpClient, httpContextAccessor)
        {
            _logger = logger;
            _configuration = configuration;

            // Cấu hình HttpClient
            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException(
                    "API Base URL không được cấu hình trong appsettings.json");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }
        /// <summary>
        /// Lấy danh sách quy tắc điểm của sự kiện
        /// GET: /api/events/{eventId}/points
        /// </summary>
        public async Task<ApiResult<List<EventPointDto>>> GetEventPointsAsync(int eventId)
        {
            try
            {
                _logger.LogInformation("Đang lấy danh sách quy tắc điểm cho sự kiện {EventId}", eventId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/events/{eventId}/points");

                if (response.IsSuccessStatusCode)
                {
                    // Ưu tiên parse theo swagger: ApiResponseDto<List<EventPointDto>>
                    ApiResponseDto<List<EventPointDto>>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<List<EventPointDto>>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse EventPointDtoListApiResponseDto cho event {EventId}", eventId);
                        apiResponse = null;
                    }

                    if (apiResponse != null)
                    {
                        if (apiResponse.Success)
                        {
                            var eventPoints = apiResponse.Data ?? new List<EventPointDto>();
                            _logger.LogInformation(
                                "Đã tải {Count} quy tắc điểm cho sự kiện {EventId}",
                                eventPoints.Count,
                                eventId);

                            return ApiResult<List<EventPointDto>>.SuccessResult(eventPoints, apiResponse.Message ?? string.Empty);
                        }

                        var message = ApiErrorReader.BuildErrorMessage(
                            apiResponse.Message ?? "Không thể tải danh sách quy tắc điểm",
                            apiResponse.Errors);
                        return ApiResult<List<EventPointDto>>.FailureResult(message);
                    }

                    // Fallback: một số API có thể trả trực tiếp list (không wrapper)
                    var content = await response.Content.ReadAsStringAsync();
                    try
                    {
                        var direct = JsonSerializer.Deserialize<List<EventPointDto>>(
                            content,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }) ?? new List<EventPointDto>();

                        return ApiResult<List<EventPointDto>>.SuccessResult(direct);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse List<EventPointDto> (fallback direct) cho event {EventId}", eventId);
                        return ApiResult<List<EventPointDto>>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<List<EventPointDto>>.FailureResult(
                        "Không tìm thấy sự kiện");
                }

                _logger.LogWarning(
                    "Không thể lấy danh sách quy tắc điểm. Status: {Status}",
                    response.StatusCode);

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tải danh sách quy tắc điểm");
                return ApiResult<List<EventPointDto>>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách quy tắc điểm cho sự kiện {EventId}", eventId);
                return ApiResult<List<EventPointDto>>.FailureResult(
                    "Đã xảy ra lỗi khi tải danh sách quy tắc điểm");
            }
        }

        /// <summary>
        /// Tạo quy tắc điểm mới
        /// POST: /api/events/{eventId}/points
        /// </summary>
        public async Task<ApiResult<EventPointDto>> CreateEventPointAsync(
            int eventId,
            CreateEventPointRequestDto request)
        {
            try
            {
                _logger.LogInformation(
                    "Đang tạo quy tắc điểm cho sự kiện {EventId}. Role: {Role}, Points: {Points}",
                    eventId,
                    request.RoleType,
                    request.Points);

                // Thêm Authorization header
                AddAuthorizationHeader();

                // Serialize request
                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync(
                    $"api/events/{eventId}/points",
                    content);

                var responseContent = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventPointDto>? apiResponse;
                    try
                    {
                        apiResponse = JsonSerializer.Deserialize<ApiResponseDto<EventPointDto>>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Failed to parse EventPointDtoApiResponseDto when creating event point");

                        // Fallback: backward compatible nếu API cũ trả thẳng EventPointDto
                        try
                        {
                            var fallback = JsonSerializer.Deserialize<EventPointDto>(
                                responseContent,
                                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                            if (fallback != null)
                            {
                                _logger.LogInformation(
                                    "Đã tạo quy tắc điểm {PointId} cho sự kiện {EventId}",
                                    fallback.EventPointID,
                                    eventId);

                                return ApiResult<EventPointDto>.SuccessResult(fallback);
                            }
                        }
                        catch (JsonException)
                        {
                            // ignore and return generic error below
                        }

                        return ApiResult<EventPointDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        _logger.LogInformation(
                            "Đã tạo quy tắc điểm {PointId} cho sự kiện {EventId}",
                            apiResponse.Data.EventPointID,
                            eventId);

                        return ApiResult<EventPointDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<EventPointDto>.FailureResult(
                        ApiErrorReader.BuildErrorMessage(
                            apiResponse?.Message ?? "Không thể tạo quy tắc điểm. Vui lòng thử lại.",
                            apiResponse?.Errors));
                }

                if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
                {
                    _logger.LogWarning("Tạo quy tắc điểm thất bại. BadRequest: {Error}", responseContent);

                    var errorMessage = "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.";
                    try
                    {
                        var apiResponse = JsonSerializer.Deserialize<ApiResponseDto<EventPointDto>>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                        if (apiResponse != null)
                        {
                            errorMessage = ApiErrorReader.BuildErrorMessage(
                                apiResponse.Message ?? errorMessage,
                                apiResponse.Errors);
                        }
                    }
                    catch (JsonException)
                    {
                        // ignore and keep default error message
                    }

                    return ApiResult<EventPointDto>.FailureResult(errorMessage);
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventPointDto>.FailureResult("Không tìm thấy sự kiện");
                }

                var message = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tạo quy tắc điểm. Vui lòng thử lại.");
                return ApiResult<EventPointDto>.FailureResult(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tạo quy tắc điểm cho sự kiện {EventId}", eventId);
                return ApiResult<EventPointDto>.FailureResult(
                    "Đã xảy ra lỗi khi tạo quy tắc điểm");
            }
        }

        /// <summary>
        /// Cập nhật quy tắc điểm
        /// PUT: /api/events/points/{eventPointId}
        /// </summary>
        public async Task<ApiResult<EventPointDto>> UpdateEventPointAsync(
            int eventPointId,
            UpdateEventPointRequestDto request)
        {
            try
            {
                _logger.LogInformation(
                    "Đang cập nhật quy tắc điểm {PointId}. Points: {Points}",
                    eventPointId,
                    request.Points);

                // Thêm Authorization header
                AddAuthorizationHeader();

                // Serialize request
                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await _httpClient.PutAsync(
                    $"api/events/points/{eventPointId}",
                    content);

                var responseContent = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventPointDto>? apiResponse;
                    try
                    {
                        apiResponse = JsonSerializer.Deserialize<ApiResponseDto<EventPointDto>>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Failed to parse EventPointDtoApiResponseDto when updating event point");

                        // Fallback: backward compatible nếu API cũ trả thẳng EventPointDto
                        try
                        {
                            var fallback = JsonSerializer.Deserialize<EventPointDto>(
                                responseContent,
                                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                            if (fallback != null)
                            {
                                _logger.LogInformation("Đã cập nhật quy tắc điểm {PointId}", eventPointId);
                                return ApiResult<EventPointDto>.SuccessResult(fallback);
                            }
                        }
                        catch (JsonException)
                        {
                            // ignore and return generic error below
                        }

                        return ApiResult<EventPointDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        _logger.LogInformation("Đã cập nhật quy tắc điểm {PointId}", eventPointId);
                        return ApiResult<EventPointDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<EventPointDto>.FailureResult(
                        ApiErrorReader.BuildErrorMessage(
                            apiResponse?.Message ?? "Không thể cập nhật quy tắc điểm",
                            apiResponse?.Errors));
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventPointDto>.FailureResult(
                        "Không tìm thấy quy tắc điểm");
                }

                if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
                {
                    var errorMessage = "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.";
                    try
                    {
                        var apiResponse = JsonSerializer.Deserialize<ApiResponseDto<EventPointDto>>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                        if (apiResponse != null)
                        {
                            errorMessage = ApiErrorReader.BuildErrorMessage(
                                apiResponse.Message ?? errorMessage,
                                apiResponse.Errors);
                        }
                    }
                    catch (JsonException)
                    {
                        // ignore and keep default error message
                    }

                    return ApiResult<EventPointDto>.FailureResult(errorMessage);
                }

                var message = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể cập nhật quy tắc điểm");
                return ApiResult<EventPointDto>.FailureResult(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật quy tắc điểm {PointId}", eventPointId);
                return ApiResult<EventPointDto>.FailureResult(
                    "Đã xảy ra lỗi khi cập nhật quy tắc điểm");
            }
        }

        // Error formatting chuẩn dùng helper chung: ApiErrorReader.BuildErrorMessage(...)

        /// <summary>
        /// Xóa quy tắc điểm
        /// DELETE: /api/events/points/{eventPointId}
        /// </summary>
        public async Task<ApiResult<bool>> DeleteEventPointAsync(int eventPointId)
        {
            try
            {
                _logger.LogInformation("Đang xóa quy tắc điểm {PointId}", eventPointId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var response = await _httpClient.DeleteAsync($"api/events/points/{eventPointId}");

                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation("Đã xóa quy tắc điểm {PointId}", eventPointId);
                    return ApiResult<bool>.SuccessResult(true);
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<bool>.FailureResult("Không tìm thấy quy tắc điểm");
                }

                if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể xóa quy tắc điểm. Có thể đã có người nhận điểm theo quy tắc này.");
                    return ApiResult<bool>.FailureResult(message);
                }

                return ApiResult<bool>.FailureResult("Không thể xóa quy tắc điểm");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi xóa quy tắc điểm {PointId}", eventPointId);
                return ApiResult<bool>.FailureResult(
                    "Đã xảy ra lỗi khi xóa quy tắc điểm");
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

