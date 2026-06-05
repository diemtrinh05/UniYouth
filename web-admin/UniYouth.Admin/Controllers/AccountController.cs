using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Helpers;
using UniYouth.Admin.Models.ViewModels.Auth;
using UniYouth.Admin.Services.Auth;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Controller xử lý authentication: Login, Logout
    /// </summary>
    public class AccountController : Controller
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AccountController> _logger;
        private readonly IConfiguration _configuration;
        private readonly JwtHelper _jwtHelper;

        private const string PasswordResetAccountSessionKey = "PasswordReset.Account";
        private const string PasswordResetVerificationTicketSessionKey = "PasswordReset.VerificationTicket";
        private const string PasswordResetVerificationTicketExpiresAtSessionKey = "PasswordReset.VerificationTicketExpiresAt";
        private const string PasswordResetLastOtpRequestedAtSessionKey = "PasswordReset.LastOtpRequestedAt";
        private const string PasswordResetOtpExpiresAtSessionKey = "PasswordReset.OtpExpiresAt";

        public AccountController(
            IAuthService authService,
            ILogger<AccountController> logger,
            IConfiguration configuration,
            JwtHelper jwtHelper)
        {
            _authService = authService;
            _logger = logger;
            _configuration = configuration;
            _jwtHelper = jwtHelper;
        }

        /// <summary>
        /// GET: /Account/Login
        /// Hiển thị trang đăng nhập
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Login(string? returnUrl = null, string? message = null)
        {
            // Nếu có cookie thì cần validate token thật sự.
            // Tránh trường hợp token hết hạn nhưng vẫn còn cookie -> redirect vòng lặp và không vào được màn hình đăng nhập.
            if (Request.Cookies.TryGetValue(AuthCookieHelper.AccessTokenCookieName, out var token) && !string.IsNullOrWhiteSpace(token))
            {
                var principal = _jwtHelper.ValidateToken(token);
                if (principal != null)
                {
                    var userInfo = _jwtHelper.ExtractUserInfo(principal);
                    if (userInfo?.HasAdminAccess == true)
                    {
                        return RedirectToAction("Index", "Home");
                    }
                }

                AuthCookieHelper.DeleteAuthCookies(Response, _configuration);
                HttpContext.Session.Clear();
                message ??= "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.";
            }

            if (Request.Cookies.TryGetValue(AuthCookieHelper.RefreshTokenCookieName, out var refreshToken)
                && !string.IsNullOrWhiteSpace(refreshToken))
            {
                var refreshResult = await _authService.RefreshTokenAsync(refreshToken);
                if (refreshResult.Success && refreshResult.Data != null)
                {
                    var rememberMe = AuthCookieHelper.IsRememberMeEnabled(Request);
                    AuthCookieHelper.SetAuthCookies(
                        Response,
                        _configuration,
                        refreshResult.Data.Token,
                        refreshResult.Data.ExpiresAt,
                        refreshResult.Data.RefreshToken,
                        refreshResult.Data.RefreshTokenExpiresAt,
                        rememberMe);
                    SyncUserSession(refreshResult.Data.User.AvatarUrl, refreshResult.Data.User.Unit?.Position);
                    return RedirectToAction("Index", "Home");
                }
            }

            // Truyền returnUrl vào view để redirect sau khi đăng nhập
            ViewData["ReturnUrl"] = returnUrl;
            ViewData["Message"] = message;

            return View(new LoginViewModel { ReturnUrl = returnUrl });
        }

        /// <summary>
        /// POST: /Account/Login
        /// Xử lý form đăng nhập
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(LoginViewModel model)
        {
            // Validate model
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            try
            {
                _logger.LogInformation("Đang xử lý đăng nhập cho tài khoản: {Code}", model.Code);

                // Gọi AuthService để đăng nhập qua API
                var result = await _authService.LoginAsync(model.Code, model.Password);

                if (!result.Success)
                {
                    // Đăng nhập thất bại - hiển thị lỗi
                    ModelState.AddModelError(string.Empty, result.Message);
                    _logger.LogWarning("Đăng nhập thất bại: {Message}", result.Message);
                    return View(model);
                }

                // Đăng nhập thành công
                if (result.Data == null)
                {
                    ModelState.AddModelError(string.Empty, "Lỗi xử lý dữ liệu đăng nhập");
                    return View(model);
                }

                // LƯU JWT TOKEN VÀO HTTPONLY COOKIE
                // QUAN TRỌNG: 
                // - HttpOnly = true: Không cho JavaScript truy cập cookie này (chống XSS)
                // - Secure = true: Chỉ gửi cookie qua HTTPS (production)
                // - SameSite = Strict: Chống CSRF attacks
                AuthCookieHelper.SetAuthCookies(
                    Response,
                    _configuration,
                    result.Data.Token,
                    result.Data.ExpiresAt,
                    result.Data.RefreshToken,
                    result.Data.RefreshTokenExpiresAt,
                    model.RememberMe);
                SyncUserSession(result.Data.User.AvatarUrl, result.Data.User.Unit?.Position);

                _logger.LogInformation(
                    "Đăng nhập thành công. User: {FullName}, Role: {Role}",
                    result.Data.User.FullName,
                    string.Join(", ", result.Data.User.Roles));

                // Hiển thị thông báo thành công
                TempData["SuccessMessage"] = $"Chào mừng {result.Data.User.FullName}!";

                // Redirect về trang yêu cầu hoặc trang chủ
                if (!string.IsNullOrEmpty(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
                {
                    return Redirect(model.ReturnUrl);
                }

                return RedirectToAction("Index", "Home");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi không xác định khi đăng nhập");
                ModelState.AddModelError(string.Empty, "Đã có lỗi xảy ra. Vui lòng thử lại sau.");
                return View(model);
            }
        }

        /// <summary>
        /// GET: /Account/Logout
        /// Fallback để tránh trường hợp người dùng truy cập trực tiếp URL logout (GET) và nhận lỗi.
        /// Khuyến nghị vẫn dùng POST + AntiForgery từ UI.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Logout(string? message = null)
        {
            _logger.LogInformation("User đang đăng xuất (GET fallback)");

            if (Request.Cookies.TryGetValue(AuthCookieHelper.RefreshTokenCookieName, out var refreshToken)
                && !string.IsNullOrWhiteSpace(refreshToken))
            {
                await _authService.RevokeTokenAsync(refreshToken);
            }

            AuthCookieHelper.DeleteAuthCookies(Response, _configuration);
            HttpContext.Session.Clear();

            message ??= "Bạn đã đăng xuất thành công.";
            return RedirectToAction(nameof(Login), new { message });
        }

        /// <summary>
        /// POST: /Account/Logout
        /// Đăng xuất - xóa cookie authentication
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            _logger.LogInformation("User đang đăng xuất");

            if (Request.Cookies.TryGetValue(AuthCookieHelper.RefreshTokenCookieName, out var refreshToken)
                && !string.IsNullOrWhiteSpace(refreshToken))
            {
                await _authService.RevokeTokenAsync(refreshToken);
            }

            AuthCookieHelper.DeleteAuthCookies(Response, _configuration);
            HttpContext.Session.Clear();

            TempData["InfoMessage"] = "Bạn đã đăng xuất thành công.";

            return RedirectToAction("Login");
        }

        /// <summary>
        /// Lưu JWT token vào HttpOnly Cookie
        /// 
        /// LÝ DO DÙNG HTTPONLY COOKIE:
        /// 1. Bảo mật: JavaScript không thể truy cập cookie này → Chống XSS attacks
        /// 2. Tự động gửi: Browser tự động gửi cookie với mỗi request đến server
        /// 3. Persistent: Cookie có thể tồn tại qua các session (nếu RememberMe = true)
        /// 
        /// KHÔNG DÙNG LocalStorage/SessionStorage VÌ:
        /// - Dễ bị tấn công XSS (JavaScript có thể đọc được)
        /// - Phải manually thêm token vào mỗi request
        /// </summary>
        /// <param name="token">JWT token từ API</param>
        /// <param name="expiresAt">Thời gian hết hạn của token</param>
        /// <param name="rememberMe">Có ghi nhớ đăng nhập không</param>
        private void SyncUserSession(string? avatarUrl, string? position)
        {
            if (HttpContext?.Session == null)
            {
                return;
            }

            if (!string.IsNullOrWhiteSpace(avatarUrl))
            {
                HttpContext.Session.SetString("CurrentUserAvatarUrl", avatarUrl);
                HttpContext.Session.SetString("CurrentUserAvatarVer", DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString());
            }

            if (!string.IsNullOrWhiteSpace(position))
            {
                HttpContext.Session.SetString("CurrentUserPosition", position);
            }
        }

        private void SavePasswordResetAccountState(
            string account,
            DateTime? otpExpiresAt = null,
            DateTime? lastOtpRequestedAt = null)
        {
            if (HttpContext?.Session == null || string.IsNullOrWhiteSpace(account))
            {
                return;
            }

            HttpContext.Session.SetString(PasswordResetAccountSessionKey, account);
            SetSessionDateTime(PasswordResetOtpExpiresAtSessionKey, otpExpiresAt);
            SetSessionDateTime(PasswordResetLastOtpRequestedAtSessionKey, lastOtpRequestedAt);
        }

        private void SavePasswordResetVerificationState(
            string verificationTicket,
            DateTime? verificationTicketExpiresAt = null)
        {
            if (HttpContext?.Session == null || string.IsNullOrWhiteSpace(verificationTicket))
            {
                return;
            }

            HttpContext.Session.SetString(PasswordResetVerificationTicketSessionKey, verificationTicket);
            SetSessionDateTime(
                PasswordResetVerificationTicketExpiresAtSessionKey,
                verificationTicketExpiresAt);
        }

        private PasswordResetFlowState GetPasswordResetFlowState()
        {
            if (HttpContext?.Session == null)
            {
                return new PasswordResetFlowState();
            }

            return new PasswordResetFlowState
            {
                Account = HttpContext.Session.GetString(PasswordResetAccountSessionKey),
                VerificationTicket = HttpContext.Session.GetString(PasswordResetVerificationTicketSessionKey),
                VerificationTicketExpiresAt = GetSessionDateTime(PasswordResetVerificationTicketExpiresAtSessionKey),
                LastOtpRequestedAt = GetSessionDateTime(PasswordResetLastOtpRequestedAtSessionKey),
                OtpExpiresAt = GetSessionDateTime(PasswordResetOtpExpiresAtSessionKey)
            };
        }

        private void ClearPasswordResetVerificationState()
        {
            if (HttpContext?.Session == null)
            {
                return;
            }

            HttpContext.Session.Remove(PasswordResetVerificationTicketSessionKey);
            HttpContext.Session.Remove(PasswordResetVerificationTicketExpiresAtSessionKey);
        }

        private void ClearPasswordResetFlowState()
        {
            if (HttpContext?.Session == null)
            {
                return;
            }

            HttpContext.Session.Remove(PasswordResetAccountSessionKey);
            HttpContext.Session.Remove(PasswordResetVerificationTicketSessionKey);
            HttpContext.Session.Remove(PasswordResetVerificationTicketExpiresAtSessionKey);
            HttpContext.Session.Remove(PasswordResetLastOtpRequestedAtSessionKey);
            HttpContext.Session.Remove(PasswordResetOtpExpiresAtSessionKey);
        }

        private void SetSessionDateTime(string key, DateTime? value)
        {
            if (HttpContext?.Session == null)
            {
                return;
            }

            if (value.HasValue)
            {
                HttpContext.Session.SetString(
                    key,
                    value.Value.ToString("o", System.Globalization.CultureInfo.InvariantCulture));
                return;
            }

            HttpContext.Session.Remove(key);
        }

        private DateTime? GetSessionDateTime(string key)
        {
            if (HttpContext?.Session == null)
            {
                return null;
            }

            var rawValue = HttpContext.Session.GetString(key);
            if (string.IsNullOrWhiteSpace(rawValue))
            {
                return null;
            }

            return DateTime.TryParse(
                rawValue,
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.RoundtripKind,
                out var parsedValue)
                ? parsedValue
                : null;
        }

        private sealed class PasswordResetFlowState
        {
            public string? Account { get; init; }
            public string? VerificationTicket { get; init; }
            public DateTime? VerificationTicketExpiresAt { get; init; }
            public DateTime? LastOtpRequestedAt { get; init; }
            public DateTime? OtpExpiresAt { get; init; }
        }

        /// <summary>
        /// GET: /Account/AccessDenied
        /// Trang báo không có quyền truy cập
        /// </summary>
        [HttpGet]
        public IActionResult AccessDenied()
        {
            return View();
        }

        /// <summary>
        /// GET: /Account/ForgotPassword
        /// </summary>
        [HttpGet]
        public IActionResult ForgotPassword()
        {
            return View(new ForgotPasswordViewModel());
        }

        /// <summary>
        /// POST: /Account/ForgotPassword
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ForgotPassword(ForgotPasswordViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var account = model.Account.Trim();
            var result = await _authService.ForgotPasswordAsync(account);

            if (result.Success)
            {
                ClearPasswordResetFlowState();
                SavePasswordResetAccountState(
                    account,
                    DateTime.UtcNow.AddMinutes(5),
                    DateTime.UtcNow);

                TempData["SuccessMessage"] = string.IsNullOrWhiteSpace(result.Message)
                    ? "Nếu tài khoản hợp lệ, mã OTP đặt lại mật khẩu đã được gửi."
                    : result.Message;

                return RedirectToAction(nameof(VerifyResetOtp));
            }

            ModelState.AddModelError(string.Empty, result.ErrorMessage ?? "Không thể gửi yêu cầu quên mật khẩu.");
            return View(model);
        }

        /// <summary>
        /// GET: /Account/VerifyResetOtp
        /// </summary>
        [HttpGet]
        public IActionResult VerifyResetOtp()
        {
            var flowState = GetPasswordResetFlowState();
            if (string.IsNullOrWhiteSpace(flowState.Account))
            {
                return RedirectToAction(nameof(ForgotPassword));
            }

            ViewData["SuccessMessage"] = TempData["SuccessMessage"];
            ViewData["ErrorMessage"] = TempData["ErrorMessage"];
            return View(BuildVerifyResetOtpViewModel(flowState));
        }

        /// <summary>
        /// POST: /Account/VerifyResetOtp
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> VerifyResetOtp(VerifyResetOtpViewModel model)
        {
            var flowState = GetPasswordResetFlowState();
            if (string.IsNullOrWhiteSpace(flowState.Account))
            {
                return RedirectToAction(nameof(ForgotPassword));
            }

            model.Account = flowState.Account;
            model.AccountDisplay = flowState.Account;
            model.OtpExpiresAt = flowState.OtpExpiresAt;

            var resendAvailableAt = GetResendAvailableAt(flowState.LastOtpRequestedAt);
            model.ResendAvailableAt = resendAvailableAt;
            model.CanResend = !resendAvailableAt.HasValue || resendAvailableAt <= DateTime.UtcNow;

            if (flowState.OtpExpiresAt.HasValue && flowState.OtpExpiresAt.Value <= DateTime.UtcNow)
            {
                model.ResendAvailableAt = DateTime.UtcNow;
                model.CanResend = true;
                ModelState.AddModelError(string.Empty, "Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.");
                return View(model);
            }

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var result = await _authService.VerifyResetOtpAsync(flowState.Account, model.OtpCode.Trim());

            if (result.Success && result.Data != null)
            {
                SavePasswordResetVerificationState(
                    result.Data.VerificationTicket,
                    result.Data.ExpiresAt);

                return RedirectToAction(nameof(ResetPassword));
            }

            ApplyApiErrorsToModelState(result.Errors);
            if (result.Errors == null || result.Errors.Count == 0)
            {
                ModelState.AddModelError(
                    string.Empty,
                    result.ErrorMessage ?? result.Message ?? "Không thể xác thực OTP.");
            }

            return View(model);
        }

        /// <summary>
        /// POST: /Account/ResendResetOtp
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ResendResetOtp()
        {
            var flowState = GetPasswordResetFlowState();
            if (string.IsNullOrWhiteSpace(flowState.Account))
            {
                return RedirectToAction(nameof(ForgotPassword));
            }

            var result = await _authService.ForgotPasswordAsync(flowState.Account);

            if (result.Success)
            {
                ClearPasswordResetVerificationState();
                SavePasswordResetAccountState(
                    flowState.Account,
                    DateTime.UtcNow.AddMinutes(5),
                    DateTime.UtcNow);

                TempData["SuccessMessage"] = string.IsNullOrWhiteSpace(result.Message)
                    ? "Nếu tài khoản hợp lệ, mã OTP đặt lại mật khẩu đã được gửi."
                    : result.Message;

                return RedirectToAction(nameof(VerifyResetOtp));
            }

            var model = BuildVerifyResetOtpViewModel(flowState);
            ViewData["ErrorMessage"] = result.ErrorMessage ?? "Không thể gửi lại mã OTP.";
            return View(nameof(VerifyResetOtp), model);
        }

        /// <summary>
        /// GET: /Account/ResetPassword?token=...
        /// </summary>
        [HttpGet]
        public IActionResult ResetPassword(string? token = null)
        {
            return HasLegacyResetToken(token)
                ? HandleLegacyResetPasswordGet(token!)
                : HandleOtpResetPasswordGet();
        }

        /// <summary>
        /// POST: /Account/ResetPassword
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ResetPassword(ResetPasswordViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            return IsLegacyResetPasswordFlow(model)
                ? await HandleLegacyResetPasswordPost(model)
                : await HandleOtpResetPasswordPost(model);
        }

        private IActionResult HandleLegacyResetPasswordGet(string token)
        {
            return View(new ResetPasswordViewModel
            {
                Token = token,
                IsLegacyTokenFlow = true
            });
        }

        private IActionResult HandleOtpResetPasswordGet()
        {
            var flowState = GetPasswordResetFlowState();
            if (string.IsNullOrWhiteSpace(flowState.VerificationTicket))
            {
                return RedirectToPasswordResetEntryPoint(flowState);
            }

            if (flowState.VerificationTicketExpiresAt.HasValue
                && flowState.VerificationTicketExpiresAt.Value <= DateTime.UtcNow)
            {
                ClearPasswordResetVerificationState();
                return RedirectToPasswordResetEntryPoint(flowState);
            }

            return View(new ResetPasswordViewModel
            {
                VerificationTicket = flowState.VerificationTicket
            });
        }

        private async Task<IActionResult> HandleLegacyResetPasswordPost(ResetPasswordViewModel model)
        {
            var result = await _authService.ResetPasswordAsync(
                model.Token,
                null,
                model.NewPassword);

            if (result.Success)
            {
                ClearPasswordResetFlowState();
                TempData["SuccessMessage"] = string.IsNullOrWhiteSpace(result.Message)
                    ? "Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại."
                    : result.Message;

                return RedirectToAction(nameof(Login));
            }

            ApplyApiErrorsToModelState(result.Errors);
            if (result.Errors == null || result.Errors.Count == 0)
            {
                ModelState.AddModelError(
                    string.Empty,
                    result.ErrorMessage ?? result.Message ?? "Không thể đặt lại mật khẩu.");
            }

            return View(model);
        }

        private async Task<IActionResult> HandleOtpResetPasswordPost(ResetPasswordViewModel model)
        {
            var flowState = GetPasswordResetFlowState();
            if (string.IsNullOrWhiteSpace(flowState.VerificationTicket))
            {
                return RedirectToPasswordResetEntryPoint(flowState);
            }

            if (flowState.VerificationTicketExpiresAt.HasValue
                && flowState.VerificationTicketExpiresAt.Value <= DateTime.UtcNow)
            {
                ClearPasswordResetVerificationState();
                return RedirectToPasswordResetEntryPoint(flowState);
            }

            model.VerificationTicket = flowState.VerificationTicket;

            var result = await _authService.ResetPasswordAsync(
                null,
                flowState.VerificationTicket,
                model.NewPassword);

            if (result.Success)
            {
                ClearPasswordResetFlowState();
                TempData["SuccessMessage"] = string.IsNullOrWhiteSpace(result.Message)
                    ? "Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại."
                    : result.Message;

                return RedirectToAction(nameof(Login));
            }

            if (IsVerificationTicketInvalidOrExpired(result))
            {
                ClearPasswordResetVerificationState();
                TempData["ErrorMessage"] = result.ErrorMessage
                    ?? result.Message
                    ?? "Phiên xác thực đặt lại mật khẩu đã hết hạn. Vui lòng bắt đầu lại.";

                return RedirectToAction(nameof(VerifyResetOtp));
            }

            ApplyApiErrorsToModelState(result.Errors);
            if (result.Errors == null || result.Errors.Count == 0)
            {
                ModelState.AddModelError(
                    string.Empty,
                    result.ErrorMessage ?? result.Message ?? "Không thể đặt lại mật khẩu.");
            }

            return View(model);
        }

        private static bool IsVerificationTicketInvalidOrExpired(
            UniYouth.Admin.Services.Common.ApiResult<object?> result)
        {
            if (ContainsVerificationTicketError(result.Message)
                || ContainsVerificationTicketError(result.ErrorMessage))
            {
                return true;
            }

            if (result.Errors == null || result.Errors.Count == 0)
            {
                return false;
            }

            foreach (var entry in result.Errors)
            {
                if (!ContainsVerificationTicketError(entry.Key))
                {
                    continue;
                }

                if (entry.Value == null || entry.Value.Length == 0)
                {
                    return true;
                }

                foreach (var error in entry.Value)
                {
                    if (ContainsVerificationTicketError(error))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        private static bool ContainsVerificationTicketError(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            return value.Contains("verification ticket", StringComparison.OrdinalIgnoreCase)
                || value.Contains("verificationticket", StringComparison.OrdinalIgnoreCase);
        }

        private static bool HasLegacyResetToken(string? token)
        {
            return !string.IsNullOrWhiteSpace(token);
        }

        private static bool IsLegacyResetPasswordFlow(ResetPasswordViewModel model)
        {
            return model.IsLegacyTokenFlow || HasLegacyResetToken(model.Token);
        }

        private IActionResult RedirectToPasswordResetEntryPoint(PasswordResetFlowState flowState)
        {
            return string.IsNullOrWhiteSpace(flowState.Account)
                ? RedirectToAction(nameof(ForgotPassword))
                : RedirectToAction(nameof(VerifyResetOtp));
        }

        private VerifyResetOtpViewModel BuildVerifyResetOtpViewModel(PasswordResetFlowState flowState)
        {
            var resendAvailableAt = GetResendAvailableAt(flowState.LastOtpRequestedAt);

            return new VerifyResetOtpViewModel
            {
                Account = flowState.Account ?? string.Empty,
                AccountDisplay = flowState.Account ?? string.Empty,
                OtpExpiresAt = flowState.OtpExpiresAt,
                ResendAvailableAt = resendAvailableAt,
                CanResend = !resendAvailableAt.HasValue || resendAvailableAt <= DateTime.UtcNow
            };
        }

        private static DateTime? GetResendAvailableAt(DateTime? lastOtpRequestedAt)
        {
            return lastOtpRequestedAt?.AddSeconds(30);
        }

        private void ApplyApiErrorsToModelState(Dictionary<string, string[]?>? errors)
        {
            if (errors == null || errors.Count == 0)
            {
                return;
            }

            foreach (var entry in errors)
            {
                var key = string.IsNullOrWhiteSpace(entry.Key) ? string.Empty : entry.Key;
                if (entry.Value == null || entry.Value.Length == 0)
                {
                    continue;
                }

                foreach (var error in entry.Value)
                {
                    if (!string.IsNullOrWhiteSpace(error))
                    {
                        ModelState.AddModelError(key, error);
                    }
                }
            }
        }
    }
}

