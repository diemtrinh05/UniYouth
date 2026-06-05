using System.Text.Json;
using UniYouth.Admin.Models.DTOs.Units;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Units
{
    public class UnitsApiService : ApiClientBase, IUnitsApiService
    {
        private readonly ILogger<UnitsApiService> _logger;

        public UnitsApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<UnitsApiService> logger,
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

        public async Task<ApiResult<IReadOnlyList<UnitOptionDto>>> GetUnitsAsync(bool activeOnly = true)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/units?activeOnly={activeOnly.ToString().ToLowerInvariant()}");
                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<IReadOnlyList<UnitOptionDto>>? api;
                    try
                    {
                        api = await ApiResponseReader.ReadAsync<IReadOnlyList<UnitOptionDto>>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse UnitOptionDto list response");
                        return ApiResult<IReadOnlyList<UnitOptionDto>>.FailureResult("Lỗi xử lý dữ liệu danh sách đơn vị từ server.");
                    }

                    if (api?.Success == true && api.Data != null)
                    {
                        return ApiResult<IReadOnlyList<UnitOptionDto>>.SuccessResult(api.Data, api.Message ?? string.Empty);
                    }

                    var message = ApiErrorReader.BuildErrorMessage(
                        api?.Message ?? "Không thể tải danh sách đơn vị.",
                        api?.Errors);
                    return ApiResult<IReadOnlyList<UnitOptionDto>>.FailureResult(message);
                }

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể tải danh sách đơn vị.");
                return ApiResult<IReadOnlyList<UnitOptionDto>>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải danh sách đơn vị");
                return ApiResult<IReadOnlyList<UnitOptionDto>>.FailureResult("Đã xảy ra lỗi khi tải danh sách đơn vị.");
            }
        }
    }
}
