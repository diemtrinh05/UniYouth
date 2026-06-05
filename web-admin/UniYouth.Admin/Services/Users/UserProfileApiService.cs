using System.Text;
using System.Text.Json;
using UniYouth.Admin.Models.DTOs.Users;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Users
{
    public class UserProfileApiService : ApiClientBase, IUserProfileApiService
    {
        private readonly ILogger<UserProfileApiService> _logger;

        public UserProfileApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<UserProfileApiService> logger,
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

        public async Task<ApiResult<UserProfileDto>> GetMeAsync()
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync("/api/Users/me");
                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể tải thông tin cá nhân");
                    return ApiResult<UserProfileDto>.FailureResult(message);
                }

                ApiResponseDto<UserProfileDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<UserProfileDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse UserProfileDtoApiResponseDto");
                    return ApiResult<UserProfileDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<UserProfileDto>.SuccessResult(apiResponse.Data, apiResponse.Message ?? "");
                }

                var errorMessage = ApiErrorReader.BuildErrorMessage(
                    apiResponse?.Message ?? "Không thể tải thông tin cá nhân",
                    apiResponse?.Errors);
                return ApiResult<UserProfileDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải thông tin cá nhân");
                return ApiResult<UserProfileDto>.FailureResult("Đã có lỗi xảy ra khi tải thông tin cá nhân");
            }
        }

        public async Task<ApiResult<UserProfileDto>> UpdateMeAsync(UpdateUserProfileDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PutAsync("/api/Users/me", content);

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể cập nhật thông tin cá nhân");
                    return ApiResult<UserProfileDto>.FailureResult(message);
                }

                ApiResponseDto<UserProfileDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<UserProfileDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse UserProfileDtoApiResponseDto khi cập nhật profile");
                    return ApiResult<UserProfileDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<UserProfileDto>.SuccessResult(apiResponse.Data, apiResponse.Message ?? "");
                }

                var errorMessage = ApiErrorReader.BuildErrorMessage(
                    apiResponse?.Message ?? "Không thể cập nhật thông tin cá nhân",
                    apiResponse?.Errors);
                return ApiResult<UserProfileDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật thông tin cá nhân");
                return ApiResult<UserProfileDto>.FailureResult("Đã có lỗi xảy ra khi cập nhật thông tin cá nhân");
            }
        }

        public async Task<ApiResult<ChangePasswordResultDto>> ChangePasswordAsync(ChangePasswordRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("/api/Users/change-password", content);

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể đổi mật khẩu");
                    return ApiResult<ChangePasswordResultDto>.FailureResult(message);
                }

                ApiResponseDto<ChangePasswordResultDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<ChangePasswordResultDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse ChangePasswordResultDtoApiResponseDto");
                    return ApiResult<ChangePasswordResultDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<ChangePasswordResultDto>.SuccessResult(apiResponse.Data, apiResponse.Message ?? "");
                }

                var errorMessage = ApiErrorReader.BuildErrorMessage(
                    apiResponse?.Message ?? "Không thể đổi mật khẩu",
                    apiResponse?.Errors);
                return ApiResult<ChangePasswordResultDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi đổi mật khẩu");
                return ApiResult<ChangePasswordResultDto>.FailureResult("Đã có lỗi xảy ra khi đổi mật khẩu");
            }
        }

        public async Task<ApiResult<AvatarUploadResultDto>> UploadAvatarAsync(Stream fileStream, string fileName, string contentType)
        {
            try
            {
                AddAuthorizationHeader();

                using var form = new MultipartFormDataContent();
                var fileContent = new StreamContent(fileStream);
                fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(contentType);
                form.Add(fileContent, "File", fileName);

                var response = await _httpClient.PostAsync("/api/Users/me/avatar", form);
                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể tải lên avatar");
                    return ApiResult<AvatarUploadResultDto>.FailureResult(message);
                }

                ApiResponseDto<AvatarUploadResultDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<AvatarUploadResultDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse AvatarUploadResultDtoApiResponseDto");
                    return ApiResult<AvatarUploadResultDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<AvatarUploadResultDto>.SuccessResult(apiResponse.Data, apiResponse.Message ?? "");
                }

                var errorMessage = ApiErrorReader.BuildErrorMessage(
                    apiResponse?.Message ?? "Không thể tải lên avatar",
                    apiResponse?.Errors);
                return ApiResult<AvatarUploadResultDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải lên avatar");
                return ApiResult<AvatarUploadResultDto>.FailureResult("Đã có lỗi xảy ra khi tải lên avatar");
            }
        }
    }
}
