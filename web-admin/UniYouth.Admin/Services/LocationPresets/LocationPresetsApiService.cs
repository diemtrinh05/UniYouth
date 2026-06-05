using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using UniYouth.Admin.Models.DTOs.LocationPresets;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.LocationPresets
{
    public class LocationPresetsApiService : ApiClientBase, ILocationPresetsApiService
    {
        private readonly ILogger<LocationPresetsApiService> _logger;
        private readonly IConfiguration _configuration;

        public LocationPresetsApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<LocationPresetsApiService> logger,
            IConfiguration configuration)
            : base(httpClient, httpContextAccessor)
        {
            _logger = logger;
            _configuration = configuration;

            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException("API Base URL không được cấu hình trong appsettings.json");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }

        public async Task<ApiResult<LocationPresetDtoPaginatedResultDto>> GetLocationPresetsAsync(
            int pageNumber = 1,
            int pageSize = 20,
            string? q = null,
            int? instituteId = null,
            bool includeInactive = false)
        {
            try
            {
                AddAuthorizationHeader();

                var query = new Dictionary<string, string?>
                {
                    ["pageNumber"] = (pageNumber <= 0 ? 1 : pageNumber).ToString(),
                    ["pageSize"] = (pageSize <= 0 ? 20 : pageSize).ToString(),
                    ["includeInactive"] = includeInactive ? "true" : "false"
                };

                if (!string.IsNullOrWhiteSpace(q))
                {
                    query["q"] = q.Trim();
                }

                if (instituteId.HasValue)
                {
                    query["instituteId"] = instituteId.Value.ToString();
                }

                var endpoint = QueryHelpers.AddQueryString("api/admin/location-presets", query);
                _logger.LogInformation("Calling API: GET {Endpoint}", endpoint);

                var response = await _httpClient.GetAsync(endpoint);
                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể tải danh sách vị trí định sẵn.");
                    return ApiResult<LocationPresetDtoPaginatedResultDto>.FailureResult(message);
                }

                ApiResponseDto<LocationPresetDtoPaginatedResultDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<LocationPresetDtoPaginatedResultDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse LocationPresetDtoPaginatedResultDtoApiResponseDto");
                    return ApiResult<LocationPresetDtoPaginatedResultDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    apiResponse.Data.Items ??= new List<LocationPresetDto>();
                    return ApiResult<LocationPresetDtoPaginatedResultDto>.SuccessResult(apiResponse.Data);
                }

                return ApiResult<LocationPresetDtoPaginatedResultDto>.FailureResult(
                    ApiErrorReader.BuildErrorMessage(
                        apiResponse?.Message ?? "Không thể tải danh sách vị trí định sẵn.",
                        apiResponse?.Errors));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách location presets");
                return ApiResult<LocationPresetDtoPaginatedResultDto>.FailureResult("Đã xảy ra lỗi khi tải danh sách vị trí định sẵn.");
            }
        }

        public async Task<ApiResult<LocationPresetDto>> GetByIdAsync(int id)
        {
            try
            {
                AddAuthorizationHeader();

                var endpoint = $"api/admin/location-presets/{id}";
                _logger.LogInformation("Calling API: GET {Endpoint}", endpoint);

                var response = await _httpClient.GetAsync(endpoint);

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<LocationPresetDto>.FailureResult("Không tìm thấy vị trí định sẵn.");
                }

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể tải vị trí định sẵn.");
                    return ApiResult<LocationPresetDto>.FailureResult(message);
                }

                ApiResponseDto<LocationPresetDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<LocationPresetDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse LocationPresetDtoApiResponseDto (GET by id)");
                    return ApiResult<LocationPresetDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<LocationPresetDto>.SuccessResult(apiResponse.Data);
                }

                return ApiResult<LocationPresetDto>.FailureResult(
                    ApiErrorReader.BuildErrorMessage(
                        apiResponse?.Message ?? "Không thể tải vị trí định sẵn.",
                        apiResponse?.Errors));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy location preset {Id}", id);
                return ApiResult<LocationPresetDto>.FailureResult("Đã xảy ra lỗi khi tải vị trí định sẵn.");
            }
        }

        public async Task<ApiResult<LocationPresetDto>> CreateAsync(CreateLocationPresetRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                _logger.LogInformation("Calling API: POST /api/admin/location-presets");

                var response = await _httpClient.PostAsync("api/admin/location-presets", content);

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể tạo vị trí định sẵn.");
                    return ApiResult<LocationPresetDto>.FailureResult(message);
                }

                ApiResponseDto<LocationPresetDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<LocationPresetDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse LocationPresetDtoApiResponseDto (create)");
                    return ApiResult<LocationPresetDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<LocationPresetDto>.SuccessResult(apiResponse.Data, apiResponse.Message ?? string.Empty);
                }

                return ApiResult<LocationPresetDto>.FailureResult(
                    ApiErrorReader.BuildErrorMessage(
                        apiResponse?.Message ?? "Không thể tạo vị trí định sẵn.",
                        apiResponse?.Errors));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tạo location preset");
                return ApiResult<LocationPresetDto>.FailureResult("Đã xảy ra lỗi khi tạo vị trí định sẵn.");
            }
        }

        public async Task<ApiResult<LocationPresetDto>> UpdateAsync(int id, UpdateLocationPresetRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var endpoint = $"api/admin/location-presets/{id}";
                _logger.LogInformation("Calling API: PUT {Endpoint}", endpoint);

                var response = await _httpClient.PutAsync(endpoint, content);

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<LocationPresetDto>.FailureResult("Không tìm thấy vị trí định sẵn.");
                }

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể cập nhật vị trí định sẵn.");
                    return ApiResult<LocationPresetDto>.FailureResult(message);
                }

                ApiResponseDto<LocationPresetDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<LocationPresetDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse LocationPresetDtoApiResponseDto (update)");
                    return ApiResult<LocationPresetDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<LocationPresetDto>.SuccessResult(apiResponse.Data, apiResponse.Message ?? string.Empty);
                }

                return ApiResult<LocationPresetDto>.FailureResult(
                    ApiErrorReader.BuildErrorMessage(
                        apiResponse?.Message ?? "Không thể cập nhật vị trí định sẵn.",
                        apiResponse?.Errors));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật location preset {Id}", id);
                return ApiResult<LocationPresetDto>.FailureResult("Đã xảy ra lỗi khi cập nhật vị trí định sẵn.");
            }
        }

        public async Task<ApiResult<bool>> DeleteAsync(int id)
        {
            try
            {
                AddAuthorizationHeader();

                var endpoint = $"api/admin/location-presets/{id}";
                _logger.LogInformation("Calling API: DELETE {Endpoint}", endpoint);

                var response = await _httpClient.DeleteAsync(endpoint);

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<bool>.FailureResult("Không tìm thấy vị trí định sẵn.");
                }

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể xóa vị trí định sẵn.");
                    return ApiResult<bool>.FailureResult(message);
                }

                ApiResponseDto? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadUntypedAsync(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse ObjectApiResponseDto (delete)");
                    apiResponse = null;
                }

                if (apiResponse?.Success == true)
                {
                    return ApiResult<bool>.SuccessResult(true, apiResponse.Message ?? string.Empty);
                }

                return ApiResult<bool>.FailureResult(
                    ApiErrorReader.BuildErrorMessage(
                        apiResponse?.Message ?? "Không thể xóa vị trí định sẵn.",
                        apiResponse?.Errors));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi xóa location preset {Id}", id);
                return ApiResult<bool>.FailureResult("Đã xảy ra lỗi khi xóa vị trí định sẵn.");
            }
        }
    }
}
