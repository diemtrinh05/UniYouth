using System.Text.Json;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Models.DTOs.Registration;
using UniYouth.Admin.Services.Attendance;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Registration
{
    public class RegistrationApiService : ApiClientBase, IRegistrationApiService
    {
        private readonly ILogger<RegistrationApiService> _logger;
        private readonly IConfiguration _configuration;

        public RegistrationApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<RegistrationApiService> logger,
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
        /// Lấy danh sách người đăng ký sự kiện
        /// GET: /api/Events/{eventId}/registrations (theo swagger)
        /// </summary>
        public async Task<ApiResult<EventRegistrationListResponseDto>> GetEventRegistrationsAsync(
            int eventId,
            int? status = null,
            int pageNumber = 1,
            int pageSize = 20)
        {
            try
            {
                if (pageNumber < 1) pageNumber = 1;
                if (pageSize < 1) pageSize = 20;

                _logger.LogInformation(
                    "Đang lấy danh sách đăng ký cho sự kiện {EventId}. Status: {Status}, PageNumber: {PageNumber}, PageSize: {PageSize}",
                    eventId,
                    status,
                    pageNumber,
                    pageSize);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var url = $"api/Events/{eventId}/registrations?pageNumber={pageNumber}&pageSize={pageSize}";
                if (status.HasValue)
                {
                    url += $"&status={status.Value}";
                }

                var response = await _httpClient.GetAsync(url);

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventRegistrationListResponseDto>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<EventRegistrationListResponseDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse EventRegistrationListResponseDtoApiResponseDto cho event {EventId}", eventId);
                        return ApiResult<EventRegistrationListResponseDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        var count = apiResponse.Data.Items?.Count ?? 0;
                        _logger.LogInformation(
                            "Đã tải {Count} đăng ký cho sự kiện {EventId}. Total: {Total}",
                            count,
                            eventId,
                            apiResponse.Data.Total);
                        return ApiResult<EventRegistrationListResponseDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<EventRegistrationListResponseDto>.FailureResult(
                        ApiErrorReader.BuildErrorMessage(
                            apiResponse?.Message ?? "Không thể tải danh sách đăng ký",
                            apiResponse?.Errors));
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventRegistrationListResponseDto>.FailureResult(
                        "Không tìm thấy sự kiện");
                }

                _logger.LogWarning(
                    "Không thể lấy danh sách đăng ký. Status: {Status}",
                    response.StatusCode);
                var message = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tải danh sách đăng ký");

                return ApiResult<EventRegistrationListResponseDto>.FailureResult(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách đăng ký cho sự kiện {EventId}", eventId);
                return ApiResult<EventRegistrationListResponseDto>.FailureResult(
                    "Đã xảy ra lỗi khi tải danh sách đăng ký");
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
                        ApiErrorReader.BuildErrorMessage(
                            apiResponse?.Message ?? "Không thể tải thông tin sự kiện",
                            apiResponse?.Errors));
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventDetailDto>.FailureResult("Không tìm thấy sự kiện");
                }

                var message = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tải thông tin sự kiện");

                return ApiResult<EventDetailDto>.FailureResult(message);
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
