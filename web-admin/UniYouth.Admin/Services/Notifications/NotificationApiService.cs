using System.Text.Json;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Notifications
{
    public class NotificationApiService : ApiClientBase, INotificationApiService
    {
        private readonly ILogger<NotificationApiService> _logger;

        public NotificationApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<NotificationApiService> logger,
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

        public async Task<ApiResult<ApiResponseDto>> GetNotificationsAsync(
            int pageNumber = 1,
            int pageSize = 20)
        {
            try
            {
                if (pageNumber < 1) pageNumber = 1;
                if (pageSize < 1) pageSize = 20;

                AddAuthorizationHeader();

                var endpoint = $"/api/notifications?pageNumber={pageNumber}&pageSize={pageSize}";
                var response = await _httpClient.GetAsync(endpoint);

                return await ReadEnvelopeAsync(response, "Không thể tải danh sách thông báo.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải danh sách thông báo.");
                return ApiResult<ApiResponseDto>.FailureResult("Đã xảy ra lỗi khi tải danh sách thông báo.");
            }
        }

        public async Task<ApiResult<ApiResponseDto>> GetUnreadCountAsync()
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync("/api/notifications/unread-count");
                return await ReadEnvelopeAsync(response, "Không thể tải số thông báo chưa đọc.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải unread count.");
                return ApiResult<ApiResponseDto>.FailureResult("Đã xảy ra lỗi khi tải số thông báo chưa đọc.");
            }
        }

        public async Task<ApiResult<ApiResponseDto>> MarkAsReadAsync(int id)
        {
            if (id <= 0)
            {
                return ApiResult<ApiResponseDto>.FailureResult("ID thông báo không hợp lệ.");
            }

            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.PutAsync($"/api/notifications/{id}/read", content: null);
                return await ReadEnvelopeAsync(response, "Không thể đánh dấu thông báo đã đọc.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi đánh dấu đã đọc thông báo id={NotificationId}.", id);
                return ApiResult<ApiResponseDto>.FailureResult("Đã xảy ra lỗi khi đánh dấu thông báo đã đọc.");
            }
        }

        public async Task<ApiResult<ApiResponseDto>> MarkAllAsReadAsync()
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.PutAsync("/api/notifications/read-all", content: null);
                return await ReadEnvelopeAsync(response, "Không thể đánh dấu tất cả thông báo đã đọc.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi đánh dấu tất cả thông báo đã đọc.");
                return ApiResult<ApiResponseDto>.FailureResult("Đã xảy ra lỗi khi đánh dấu tất cả thông báo đã đọc.");
            }
        }

        private async Task<ApiResult<ApiResponseDto>> ReadEnvelopeAsync(
            HttpResponseMessage response,
            string defaultErrorMessage)
        {
            var statusCode = (int)response.StatusCode;

            if (response.IsSuccessStatusCode)
            {
                ApiResponseDto? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadUntypedAsync(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse ObjectApiResponseDto.");
                    return FailureResultWithStatus("Lỗi xử lý dữ liệu từ server.", statusCode);
                }

                if (apiResponse?.Success == true)
                {
                    return SuccessResultWithStatus(
                        apiResponse,
                        apiResponse.Message ?? string.Empty,
                        statusCode);
                }

                var errorMessage = ApiErrorReader.BuildErrorMessage(
                    apiResponse?.Message ?? defaultErrorMessage,
                    apiResponse?.Errors);
                return FailureResultWithStatus(errorMessage, statusCode);
            }

            var message = await ApiErrorReader.ReadErrorMessageAsync(response, defaultErrorMessage);
            return FailureResultWithStatus(message, statusCode);
        }

        private static ApiResult<ApiResponseDto> SuccessResultWithStatus(
            ApiResponseDto data,
            string message,
            int statusCode)
        {
            return new ApiResult<ApiResponseDto>
            {
                Success = true,
                Data = data,
                ErrorMessage = message,
                Summary = statusCode
            };
        }

        private static ApiResult<ApiResponseDto> FailureResultWithStatus(
            string message,
            int statusCode)
        {
            return new ApiResult<ApiResponseDto>
            {
                Success = false,
                Data = default,
                ErrorMessage = message,
                Summary = statusCode
            };
        }
    }
}
