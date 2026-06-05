using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Auth;
using UniYouth.Api.Contracts.DTOs.Common;

namespace UniYouth.Api.Controllers
{

    /// <summary>
    /// Controller xử lý các chức năng xác thực người dùng (Authentication)
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Produces("application/json")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly IPasswordResetService _passwordResetService;
        private readonly IPasswordResetOtpService _passwordResetOtpService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthController> _logger;

        public AuthController(
            IAuthService authService,
            IPasswordResetService passwordResetService,
            IPasswordResetOtpService passwordResetOtpService,
            IConfiguration configuration,
            ILogger<AuthController> logger)
        {
            _authService = authService;
            _passwordResetService = passwordResetService;
            _passwordResetOtpService = passwordResetOtpService;
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// API đăng nhập người dùng - Trả về JWT Token nếu thông tin hợp lệ
        /// </summary>
        /// <param name="request">Thông tin đăng nhập (Code và Mật khẩu)</param>
        /// <returns>JWT Token kèm thông tin người dùng</returns>
        /// <response code="200">Đăng nhập thành công, trả về token</response>
        /// <response code="401">Sai thông tin đăng nhập hoặc tài khoản bị vô hiệu hóa</response>
        /// <response code="400">Dữ liệu gửi lên không hợp lệ</response>
        /// <remarks>
        /// Ví dụ request:
        ///
        ///     POST /api/auth/login
        ///     {
        ///         "Code": "ADMIN001",
        ///         "password": "password123"
        ///     }
        ///
        /// </remarks>
        [HttpPost("login")]
        [EnableRateLimiting("Login")]
        [ProducesResponseType(typeof(ApiResponseDto<LoginResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
        {
            // Kiểm tra dữ liệu đầu vào
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            // Gọi tầng Service để xử lý nghiệp vụ đăng nhập
            var result = await _authService.LoginAsync(
                request,
                Shared.Helpers.ClientIpHelper.GetClientIpAddress(HttpContext),
                Request.Headers["User-Agent"].ToString());

            if (result == null)
            {
                // Đăng nhập thất bại: sai thông tin hoặc tài khoản bị vô hiệu hóa
                return Unauthorized(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Tài khoản hoặc mật khẩu không đúng, hoặc tài khoản đã bị vô hiệu hóa"
                });
            }

            // Đăng nhập thành công
            return Ok(new ApiResponseDto<LoginResponseDto>
            {
                Success = true,
                Message = "Đăng nhập thành công",
                Data = result
            });
        }

        [HttpPost("refresh")]
        [ProducesResponseType(typeof(ApiResponseDto<LoginResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequestDto request)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            var result = await _authService.RefreshTokenAsync(
                request.RefreshToken,
                Shared.Helpers.ClientIpHelper.GetClientIpAddress(HttpContext),
                Request.Headers["User-Agent"].ToString());

            if (result == null)
            {
                return Unauthorized(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Refresh token không hợp lệ hoặc đã hết hạn"
                });
            }

            return Ok(new ApiResponseDto<LoginResponseDto>
            {
                Success = true,
                Message = "Làm mới phiên đăng nhập thành công",
                Data = result
            });
        }

        [HttpPost("revoke")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> Revoke([FromBody] RevokeTokenRequestDto request)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            await _authService.RevokeRefreshTokenAsync(
                request.RefreshToken,
                Shared.Helpers.ClientIpHelper.GetClientIpAddress(HttpContext),
                Request.Headers["User-Agent"].ToString(),
                "logout");

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Thu hồi refresh token thành công"
            });
        }

        /// <summary>
        /// API kiểm tra trạng thái hoạt động của dịch vụ xác thực
        /// </summary>
        /// <returns>Trạng thái hoạt động của service</returns>
        /// <response code="200">Dịch vụ đang hoạt động bình thường</response>
        [HttpGet("health")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        public IActionResult Health()
        {
            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "OK",
                Data = new
                {
                    status = "healthy",
                    service = "Authentication",
                    timestamp = DateTime.Now
                }
            });
        }

        /// <summary>
        /// API yêu cầu đặt lại mật khẩu (Forgot Password)
        /// - Nhận tài khoản, tra cứu email của tài khoản đó để gửi OTP
        /// - Luôn trả về response giống nhau để tránh lộ tài khoản có tồn tại hay không
        /// </summary>
        /// <response code="200">Luôn trả về thông báo chung</response>
        /// <response code="400">Dữ liệu gửi lên không hợp lệ</response>
        [HttpPost("forgot-password")]
        [EnableRateLimiting("ForgotPassword")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequestDto request)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            await _passwordResetService.RequestForgotPasswordAsync(request.Account);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Nếu tài khoản hợp lệ, mã OTP đặt lại mật khẩu đã được gửi."
            });
        }

        /// <summary>
        /// API xác thực OTP đặt lại mật khẩu và cấp verification ticket ngắn hạn
        /// </summary>
        /// <response code="200">Xác thực OTP thành công</response>
        /// <response code="400">OTP không hợp lệ / hết hạn / dữ liệu không hợp lệ</response>
        [HttpPost("verify-reset-otp")]
        [ProducesResponseType(typeof(ApiResponseDto<VerifyResetOtpResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> VerifyResetOtp([FromBody] VerifyResetOtpRequestDto request, CancellationToken cancellationToken)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            var result = await _passwordResetOtpService.VerifyResetOtpAsync(
                request.Account,
                request.OtpCode,
                cancellationToken);

            if (!result.Success || string.IsNullOrWhiteSpace(result.VerificationTicket) || !result.ExpiresAt.HasValue)
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = result.Message
                });
            }

            return Ok(new ApiResponseDto<VerifyResetOtpResponseDto>
            {
                Success = true,
                Message = "Xác thực OTP thành công.",
                Data = new VerifyResetOtpResponseDto
                {
                    VerificationTicket = result.VerificationTicket,
                    ExpiresAt = result.ExpiresAt.Value
                }
            });
        }

        /// <summary>
        /// API xác nhận đặt lại mật khẩu bằng token
        /// </summary>
        /// <response code="200">Đặt lại mật khẩu thành công</response>
        /// <response code="400">Token không hợp lệ / hết hạn / mật khẩu không hợp lệ</response>
        [HttpPost("reset-password")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequestDto request, CancellationToken cancellationToken)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            var hasLegacyToken = !string.IsNullOrWhiteSpace(request.Token);
            var hasVerificationTicket = !string.IsNullOrWhiteSpace(request.VerificationTicket);

            if (hasLegacyToken == hasVerificationTicket)
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = new Dictionary<string, string[]>
                    {
                        ["resetCredential"] = ["Phải cung cấp duy nhất token hoặc verificationTicket."]
                    }
                });
            }

            if (hasVerificationTicket)
            {
                var otpResult = await _passwordResetOtpService.ResetPasswordWithVerificationTicketAsync(
                    request.VerificationTicket!,
                    request.NewPassword,
                    cancellationToken);

                if (!otpResult.Success)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = otpResult.Message
                    });
                }

                return Ok(new ApiResponseDto<object>
                {
                    Success = true,
                    Message = "Đặt lại mật khẩu thành công."
                });
            }

            var allowLegacyTokenReset = _configuration.GetValue("PasswordReset:AllowLegacyTokenReset", true);
            if (!allowLegacyTokenReset)
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Reset password bằng link cũ đã ngừng hỗ trợ."
                });
            }

            var result = await _passwordResetService.ResetPasswordAsync(
                request.Token!,
                request.NewPassword,
                cancellationToken);
            if (!result.Success)
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = result.Message
                });
            }

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Đặt lại mật khẩu thành công."
            });
        }
    }
}


