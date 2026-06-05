using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using UniYouth.Admin.Models.DTOs.Auth;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Auth
{

    /// <summary>
    /// Interface cho AuthService
    /// Dùng để Dependency Injection
    /// </summary>
    public interface IAuthService
    {
        Task<LoginResult> LoginAsync(string code, string password);
        Task<ApiResult<LoginResponseDto?>> RefreshTokenAsync(string refreshToken);
        Task<ApiResult<object?>> RevokeTokenAsync(string refreshToken);
        Task<bool> CheckApiHealthAsync();
        Task<ApiResult<object?>> ForgotPasswordAsync(string account);
        Task<ApiResult<VerifyResetOtpResponseDto?>> VerifyResetOtpAsync(string account, string otpCode);
        Task<ApiResult<object?>> ResetPasswordAsync(
            string? token,
            string? verificationTicket,
            string newPassword);
    }
    /// <summary>
    /// Service xử lý authentication với Backend API
    /// Chịu trách nhiệm gọi API đăng nhập và xử lý response
    /// </summary>
    public class AuthService : IAuthService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            HttpClient httpClient,
            IConfiguration configuration,
            ILogger<AuthService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _logger = logger;

            // Lấy Base URL từ appsettings.json
            var baseUrl = _configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException("API Base URL không được cấu hình trong appsettings.json");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));
        }

        /// <summary>
        /// Gọi API đăng nhập
        /// Endpoint: POST /api/Auth/login
        /// </summary>
        /// <param name="code">Tài khoản</param>
        /// <param name="password">Mật khẩu</param>
        /// <returns>Kết quả đăng nhập bao gồm JWT token</returns>
        public async Task<LoginResult> LoginAsync(string code, string password)
        {
            try
            {
                _logger.LogInformation("Đang thực hiện đăng nhập cho tài khoản: {Code}", code);

                // Tạo request body theo đúng schema API
                var loginRequest = new LoginRequestDto
                {
                    Code = code,
                    Password = password
                };

                // Serialize request thành JSON
                var jsonContent = JsonSerializer.Serialize(loginRequest, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                // Gọi API endpoint
                var response = await _httpClient.PostAsync("/api/Auth/login", content);

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<LoginResponseDto>? apiResponse;

                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<LoginResponseDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse LoginResponseDtoApiResponseDto từ API");
                        return new LoginResult
                        {
                            Success = false,
                            Message = "Lỗi xử lý dữ liệu từ server."
                        };
                    }

                    if (apiResponse == null)
                    {
                        _logger.LogError("API trả về body rỗng cho login");
                        return new LoginResult
                        {
                            Success = false,
                            Message = "Lỗi xử lý dữ liệu từ server."
                        };
                    }

                    if (!apiResponse.Success)
                    {
                        var errorMessage = ApiErrorReader.BuildErrorMessage(
                            apiResponse.Message ?? "Đăng nhập thất bại.",
                            apiResponse.Errors);

                        _logger.LogWarning("Đăng nhập thất bại. Message: {Message}", errorMessage);

                        return new LoginResult
                        {
                            Success = false,
                            Message = errorMessage
                        };
                    }

                    var loginResponse = apiResponse.Data;

                    if (loginResponse?.User == null)
                    {
                        _logger.LogError("API trả về success=true nhưng thiếu data/user");
                        return new LoginResult
                        {
                            Success = false,
                            Message = "Lỗi xử lý dữ liệu từ server."
                        };
                    }

                    // Kiểm tra user có role Admin hoặc CanBo không
                    if (!IsAuthorizedRole(loginResponse.User.Roles))
                    {
                        _logger.LogWarning(
                            "User {Code} không có quyền truy cập Admin. Roles: {Roles}",
                            code,
                            string.Join(", ", loginResponse.User.Roles));

                        return new LoginResult
                        {
                            Success = false,
                            Message = "Bạn không có quyền truy cập hệ thống quản trị. Chỉ Admin và Cán bộ mới được phép đăng nhập."
                        };
                    }

                    _logger.LogInformation("Đăng nhập thành công cho user: {FullName}", loginResponse.User.FullName);

                    return new LoginResult
                    {
                        Success = true,
                        Message = apiResponse.Message ?? "Đăng nhập thành công",
                        Data = loginResponse
                    };
                }
                else if (response.StatusCode == HttpStatusCode.Unauthorized
                         || response.StatusCode == HttpStatusCode.BadRequest)
                {
                    var message = "Tài khoản hoặc mật khẩu không chính xác";
                    message = await ApiErrorReader.ReadErrorMessageAsync(response, message);

                    _logger.LogWarning("Đăng nhập thất bại. Status: {Status}. Message: {Message}", response.StatusCode, message);
                    return new LoginResult
                    {
                        Success = false,
                        Message = message
                    };
                }
                else
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Đã có lỗi xảy ra. Vui lòng thử lại sau.");
                    _logger.LogError("API trả về lỗi: {StatusCode}. Message: {Message}", response.StatusCode, message);
                    return new LoginResult
                    {
                        Success = false,
                        Message = message
                    };
                }
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, "Lỗi kết nối đến API");
                return new LoginResult
                {
                    Success = false,
                    Message = "Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng."
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi không xác định khi đăng nhập");
                return new LoginResult
                {
                    Success = false,
                    Message = "Đã có lỗi xảy ra. Vui lòng thử lại sau."
                };
            }
        }

        /// <summary>
        /// Kiểm tra xem user có role được phép truy cập Admin web không
        /// Chỉ Admin và CanBo mới được phép
        /// </summary>
        /// <param name="roles">Danh sách roles của user</param>
        /// <returns>True nếu có quyền, False nếu không</returns>
        private bool IsAuthorizedRole(List<string> roles)
        {
            if (roles == null || !roles.Any())
            {
                return false;
            }

            // Kiểm tra có chứa role Admin hoặc CanBo không (case-insensitive)
            return roles.Any(r =>
                r.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                r.Equals("CanBo", StringComparison.OrdinalIgnoreCase));
        }

        public async Task<ApiResult<object?>> ForgotPasswordAsync(string account)
        {
            try
            {
                var request = new ForgotPasswordRequestDto { Account = account };

                var jsonContent = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync("/api/Auth/forgot-password", content);

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadUntypedAsync(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse ObjectApiResponseDto từ API forgot-password");
                        return ApiResult<object?>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true)
                    {
                        return ApiResult<object?>.SuccessResult(null, apiResponse.Message ?? string.Empty);
                    }

                    var message = apiResponse?.Message ?? "Không thể gửi yêu cầu quên mật khẩu.";
                    return ApiResult<object?>.FailureResult(
                        message,
                        apiResponse?.Errors,
                        ApiErrorReader.BuildErrorMessage(message, apiResponse?.Errors));
                }

                var errorInfo = await ApiErrorReader.ReadErrorAsync(
                    response,
                    "Không thể gửi yêu cầu quên mật khẩu. Vui lòng thử lại.");
                return ApiResult<object?>.FailureResult(
                    errorInfo.Message,
                    errorInfo.Errors,
                    errorInfo.DisplayMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi không xác định khi gọi forgot-password");
                return ApiResult<object?>.FailureResult("Đã có lỗi xảy ra. Vui lòng thử lại sau.");
            }
        }

        public async Task<ApiResult<LoginResponseDto?>> RefreshTokenAsync(string refreshToken)
        {
            try
            {
                var request = new RefreshTokenRequestDto
                {
                    RefreshToken = refreshToken
                };

                var jsonContent = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("/api/Auth/refresh", content);

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể làm mới phiên đăng nhập.");
                    return ApiResult<LoginResponseDto?>.FailureResult(message);
                }

                ApiResponseDto<LoginResponseDto>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<LoginResponseDto>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse refresh token response");
                    return ApiResult<LoginResponseDto?>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success != true || apiResponse.Data == null)
                {
                    return ApiResult<LoginResponseDto?>.FailureResult(
                        apiResponse?.Message ?? "Không thể làm mới phiên đăng nhập.");
                }

                return ApiResult<LoginResponseDto?>.SuccessResult(
                    apiResponse.Data,
                    apiResponse.Message ?? "Làm mới phiên đăng nhập thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi refresh token cho Admin Web");
                return ApiResult<LoginResponseDto?>.FailureResult("Không thể làm mới phiên đăng nhập.");
            }
        }

        public async Task<ApiResult<object?>> RevokeTokenAsync(string refreshToken)
        {
            try
            {
                var request = new RevokeTokenRequestDto
                {
                    RefreshToken = refreshToken
                };

                var jsonContent = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("/api/Auth/revoke", content);

                if (!response.IsSuccessStatusCode)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể thu hồi phiên đăng nhập.");
                    return ApiResult<object?>.FailureResult(message);
                }

                ApiResponseDto? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadUntypedAsync(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse revoke token response");
                    return ApiResult<object?>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                return apiResponse?.Success == true
                    ? ApiResult<object?>.SuccessResult(null, apiResponse.Message ?? "Thu hồi phiên đăng nhập thành công")
                    : ApiResult<object?>.FailureResult(apiResponse?.Message ?? "Không thể thu hồi phiên đăng nhập.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi revoke token cho Admin Web");
                return ApiResult<object?>.FailureResult("Không thể thu hồi phiên đăng nhập.");
            }
        }

        public async Task<ApiResult<VerifyResetOtpResponseDto?>> VerifyResetOtpAsync(string account, string otpCode)
        {
            try
            {
                var request = new VerifyResetOtpRequestDto
                {
                    Account = account,
                    OtpCode = otpCode
                };

                var jsonContent = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync("/api/Auth/verify-reset-otp", content);

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<VerifyResetOtpResponseDto>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<VerifyResetOtpResponseDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse VerifyResetOtpResponseDtoApiResponseDto từ API verify-reset-otp");
                        return ApiResult<VerifyResetOtpResponseDto?>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        return ApiResult<VerifyResetOtpResponseDto?>.SuccessResult(
                            apiResponse.Data,
                            apiResponse.Message ?? string.Empty);
                    }

                    var message = apiResponse?.Message ?? "Không thể xác thực OTP.";
                    return ApiResult<VerifyResetOtpResponseDto?>.FailureResult(
                        message,
                        apiResponse?.Errors,
                        ApiErrorReader.BuildErrorMessage(message, apiResponse?.Errors));
                }

                var errorInfo = await ApiErrorReader.ReadErrorAsync(
                    response,
                    "Không thể xác thực OTP. Vui lòng thử lại.");
                return ApiResult<VerifyResetOtpResponseDto?>.FailureResult(
                    errorInfo.Message,
                    errorInfo.Errors,
                    errorInfo.DisplayMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi không xác định khi gọi verify-reset-otp");
                return ApiResult<VerifyResetOtpResponseDto?>.FailureResult("Đã có lỗi xảy ra. Vui lòng thử lại sau.");
            }
        }

        public async Task<ApiResult<object?>> ResetPasswordAsync(
            string? token,
            string? verificationTicket,
            string newPassword)
        {
            try
            {
                var request = new ResetPasswordRequestDto
                {
                    Token = token,
                    VerificationTicket = verificationTicket,
                    NewPassword = newPassword
                };

                var jsonContent = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync("/api/Auth/reset-password", content);

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadUntypedAsync(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse ObjectApiResponseDto từ API reset-password");
                        return ApiResult<object?>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true)
                    {
                        return ApiResult<object?>.SuccessResult(null, apiResponse.Message ?? string.Empty);
                    }

                    var message = apiResponse?.Message ?? "Không thể đặt lại mật khẩu.";
                    return ApiResult<object?>.FailureResult(
                        message,
                        apiResponse?.Errors,
                        ApiErrorReader.BuildErrorMessage(message, apiResponse?.Errors));
                }

                var errorInfo = await ApiErrorReader.ReadErrorAsync(
                    response,
                    "Không thể đặt lại mật khẩu. Vui lòng thử lại.");
                return ApiResult<object?>.FailureResult(
                    errorInfo.Message,
                    errorInfo.Errors,
                    errorInfo.DisplayMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi không xác định khi gọi reset-password");
                return ApiResult<object?>.FailureResult("Đã có lỗi xảy ra. Vui lòng thử lại sau.");
            }
        }

        /// <summary>
        /// Kiểm tra health của API
        /// Endpoint: GET /api/Auth/health
        /// </summary>
        /// <returns>True nếu API hoạt động bình thường</returns>
        public async Task<bool> CheckApiHealthAsync()
        {
            try
            {
                var response = await _httpClient.GetAsync("/api/Auth/health");
                return response.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }
    }

}

