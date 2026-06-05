using System.Text;
using System.Text.Json;
using UniYouth.Admin.Models.DTOs.AdminUsers;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.AdminUsers
{
    public class AdminUsersApiService : ApiClientBase, IAdminUsersApiService
    {
        private readonly ILogger<AdminUsersApiService> _logger;
        private readonly IConfiguration _configuration;

        public AdminUsersApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<AdminUsersApiService> logger,
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

        public async Task<ApiResult<AdminUserListItemDtoPaginatedResultDto>> GetUsersAsync(
            int pageNumber = 1,
            int pageSize = 20,
            string? search = null,
            int? status = null,
            string? role = null)
        {
            try
            {
                AddAuthorizationHeader();

                var query = new List<string>();
                if (pageNumber > 0) query.Add($"pageNumber={pageNumber}");
                if (pageSize > 0) query.Add($"pageSize={pageSize}");
                if (!string.IsNullOrWhiteSpace(search)) query.Add($"search={Uri.EscapeDataString(search.Trim())}");
                if (status.HasValue) query.Add($"status={status.Value}");
                if (!string.IsNullOrWhiteSpace(role)) query.Add($"role={Uri.EscapeDataString(role.Trim())}");

                var endpoint = "api/admin/users" + (query.Count > 0 ? "?" + string.Join("&", query) : "");
                var response = await _httpClient.GetAsync(endpoint);

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<AdminUserListItemDtoPaginatedResultDto>? api;
                    try
                    {
                        api = await ApiResponseReader.ReadAsync<AdminUserListItemDtoPaginatedResultDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse AdminUserListItemDtoPaginatedResultDtoApiResponseDto");
                        return ApiResult<AdminUserListItemDtoPaginatedResultDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (api?.Success == true && api.Data != null)
                    {
                        api.Data.Items ??= new List<AdminUserListItemDto>();
                        return ApiResult<AdminUserListItemDtoPaginatedResultDto>.SuccessResult(api.Data, api.Message ?? "");
                    }

                    var message = ApiErrorReader.BuildErrorMessage(
                        api?.Message ?? "Không thể tải danh sách người dùng.",
                        api?.Errors);
                    return ApiResult<AdminUserListItemDtoPaginatedResultDto>.FailureResult(message);
                }

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể tải danh sách người dùng.");
                return ApiResult<AdminUserListItemDtoPaginatedResultDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải danh sách người dùng admin");
                return ApiResult<AdminUserListItemDtoPaginatedResultDto>.FailureResult("Đã xảy ra lỗi khi tải danh sách người dùng.");
            }
        }

        public async Task<ApiResult<AdminUserDetailDto>> GetUserByIdAsync(int userId)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/admin/users/{userId}");

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<AdminUserDetailDto>.FailureResult("Không tìm thấy người dùng.");
                }

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<AdminUserDetailDto>? api;
                    try
                    {
                        api = await ApiResponseReader.ReadAsync<AdminUserDetailDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse AdminUserDetailDtoApiResponseDto (userId={UserId})", userId);
                        return ApiResult<AdminUserDetailDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (api?.Success == true && api.Data != null)
                    {
                        return ApiResult<AdminUserDetailDto>.SuccessResult(api.Data, api.Message ?? "");
                    }

                    var message = ApiErrorReader.BuildErrorMessage(
                        api?.Message ?? "Không thể tải thông tin người dùng.",
                        api?.Errors);
                    return ApiResult<AdminUserDetailDto>.FailureResult(message);
                }

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tải thông tin người dùng.");
                return ApiResult<AdminUserDetailDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải thông tin người dùng admin userId={UserId}", userId);
                return ApiResult<AdminUserDetailDto>.FailureResult("Đã xảy ra lỗi khi tải thông tin người dùng.");
            }
        }

        public async Task<ApiResult<AdminUserDetailDto>> UpdateUserAsync(int userId, UpdateAdminUserRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PutAsync($"api/admin/users/{userId}", content);

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<AdminUserDetailDto>.FailureResult("Không tìm thấy người dùng.");
                }

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<AdminUserDetailDto>? api;
                    try
                    {
                        api = await ApiResponseReader.ReadAsync<AdminUserDetailDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse AdminUserDetailDtoApiResponseDto khi update userId={UserId}", userId);
                        return ApiResult<AdminUserDetailDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (api?.Success == true && api.Data != null)
                    {
                        return ApiResult<AdminUserDetailDto>.SuccessResult(api.Data, api.Message ?? "");
                    }

                    var message = ApiErrorReader.BuildErrorMessage(
                        api?.Message ?? "Không thể cập nhật người dùng.",
                        api?.Errors);
                    return ApiResult<AdminUserDetailDto>.FailureResult(message);
                }

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể cập nhật người dùng.");
                return ApiResult<AdminUserDetailDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật người dùng admin userId={UserId}", userId);
                return ApiResult<AdminUserDetailDto>.FailureResult("Đã xảy ra lỗi khi cập nhật người dùng.");
            }
        }

        public async Task<ApiResult<string?>> CreateUserAsync(CreateUserRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("api/admin/users", content);

                return await ReadObjectApiResponseAsync(response, "Không thể tạo người dùng");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tạo người dùng");
                return ApiResult<string?>.FailureResult("Đã xảy ra lỗi khi tạo người dùng");
            }
        }

        public async Task<ApiResult<string?>> UpdateUserRolesAsync(int userId, UpdateUserRolesRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PutAsync($"api/admin/users/{userId}/roles", content);

                return await ReadObjectApiResponseAsync(response, "Không thể cập nhật roles");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật roles userId={UserId}", userId);
                return ApiResult<string?>.FailureResult("Đã xảy ra lỗi khi cập nhật roles");
            }
        }

        public async Task<ApiResult<string?>> UpdateUserStatusAsync(int userId, UpdateUserStatusRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PutAsync($"api/admin/users/{userId}/status", content);

                return await ReadObjectApiResponseAsync(response, "Không thể cập nhật trạng thái");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật trạng thái userId={UserId}", userId);
                return ApiResult<string?>.FailureResult("Đã xảy ra lỗi khi cập nhật trạng thái");
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
