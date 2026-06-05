using System.Text.Json;
using UniYouth.Admin.Models.DTOs.Positions;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Positions
{
    public class PositionsApiService : ApiClientBase, IPositionsApiService
    {
        private readonly ILogger<PositionsApiService> _logger;

        public PositionsApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<PositionsApiService> logger,
            IConfiguration configuration)
            : base(httpClient, httpContextAccessor)
        {
            _logger = logger;

            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrWhiteSpace(baseUrl))
            {
                throw new InvalidOperationException("API Base URL không được cấu hình trong appsettings.json");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }

        public async Task<ApiResult<IReadOnlyList<PositionOptionDto>>> GetPositionsAsync(bool activeOnly = true)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/positions?activeOnly={activeOnly.ToString().ToLowerInvariant()}");
                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<IReadOnlyList<PositionOptionDto>>? api;
                    try
                    {
                        api = await ApiResponseReader.ReadAsync<IReadOnlyList<PositionOptionDto>>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse PositionOptionDto list response");
                        return ApiResult<IReadOnlyList<PositionOptionDto>>.FailureResult("Lỗi xử lý dữ liệu danh sách chức vụ từ server.");
                    }

                    if (api?.Success == true && api.Data != null)
                    {
                        return ApiResult<IReadOnlyList<PositionOptionDto>>.SuccessResult(api.Data, api.Message ?? string.Empty);
                    }

                    var message = ApiErrorReader.BuildErrorMessage(
                        api?.Message ?? "Không thể tải danh sách chức vụ.",
                        api?.Errors);
                    return ApiResult<IReadOnlyList<PositionOptionDto>>.FailureResult(message);
                }

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể tải danh sách chức vụ.");
                return ApiResult<IReadOnlyList<PositionOptionDto>>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải danh sách chức vụ");
                return ApiResult<IReadOnlyList<PositionOptionDto>>.FailureResult("Đã xảy ra lỗi khi tải danh sách chức vụ.");
            }
        }
    }
}
