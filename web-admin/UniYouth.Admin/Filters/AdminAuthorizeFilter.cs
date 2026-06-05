using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using UniYouth.Admin.Helpers;
using UniYouth.Admin.Services.Auth;

namespace UniYouth.Admin.Filters
{
    public class AdminAuthorizeFilter : IAsyncAuthorizationFilter
    {
        private readonly JwtHelper _jwtHelper;
        private readonly IAuthService _authService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AdminAuthorizeFilter> _logger;

        private static readonly string[] AllowedPaths = new[]
        {
            "/account/login",
            "/account/logout",
            "/account/forgotpassword",
            "/account/verifyresetotp",
            "/account/resendresetotp",
            "/account/resetpassword",
            "/account/accessdenied"
        };

        public AdminAuthorizeFilter(
            JwtHelper jwtHelper,
            IAuthService authService,
            IConfiguration configuration,
            ILogger<AdminAuthorizeFilter> logger)
        {
            _jwtHelper = jwtHelper;
            _authService = authService;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
        {
            var path = context.HttpContext.Request.Path.Value?.ToLower() ?? string.Empty;
            if (IsAllowedPath(path))
            {
                TryAttachUserIdentity(context.HttpContext);
                return;
            }

            var token = GetAccessToken(context.HttpContext.Request);
            if (string.IsNullOrWhiteSpace(token))
            {
                if (await TryRefreshSessionAsync(context.HttpContext))
                {
                    token = GetAccessToken(context.HttpContext.Request);
                }
            }

            if (string.IsNullOrWhiteSpace(token))
            {
                _logger.LogWarning("Không tìm thấy access token cookie. Redirect đến Login");
                RedirectToLogin(context);
                return;
            }

            var principal = _jwtHelper.ValidateToken(token);
            if (principal == null && await TryRefreshSessionAsync(context.HttpContext))
            {
                token = GetAccessToken(context.HttpContext.Request);
                principal = string.IsNullOrWhiteSpace(token) ? null : _jwtHelper.ValidateToken(token);
            }

            if (principal == null)
            {
                _logger.LogWarning("Token không hợp lệ hoặc đã hết hạn. Redirect đến Login");
                AuthCookieHelper.DeleteAuthCookies(context.HttpContext.Response, _configuration);
                context.HttpContext.Session.Clear();
                context.Result = new RedirectToActionResult(
                    "Login",
                    "Account",
                    new { message = "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại." });
                return;
            }

            var userInfo = _jwtHelper.ExtractUserInfo(principal);
            if (userInfo == null)
            {
                _logger.LogWarning("Không thể extract user info từ token hợp lệ");
                RedirectToLogin(context);
                return;
            }

            if (!userInfo.HasAdminAccess)
            {
                _logger.LogWarning(
                    "User {UserId} với role {Role} không có quyền truy cập Admin web",
                    userInfo.UserId,
                    userInfo.RolesDisplay);

                context.Result = new ViewResult
                {
                    ViewName = "~/Views/Shared/Forbidden.cshtml",
                    StatusCode = 403
                };
                return;
            }

            context.HttpContext.User = principal;
            context.HttpContext.Items["UserInfo"] = userInfo;
            context.HttpContext.Items["UserId"] = userInfo.UserId;
            context.HttpContext.Items["UserRole"] = userInfo.RolesDisplay;
            context.HttpContext.Items["UserEmail"] = userInfo.Email;
            context.HttpContext.Items["UserFullName"] = userInfo.FullName;
        }

        private async Task<bool> TryRefreshSessionAsync(HttpContext httpContext)
        {
            if (!httpContext.Request.Cookies.TryGetValue(AuthCookieHelper.RefreshTokenCookieName, out var refreshToken)
                || string.IsNullOrWhiteSpace(refreshToken))
            {
                return false;
            }

            var refreshResult = await _authService.RefreshTokenAsync(refreshToken);
            if (!refreshResult.Success || refreshResult.Data == null)
            {
                return false;
            }

            var rememberMe = AuthCookieHelper.IsRememberMeEnabled(httpContext.Request);
            AuthCookieHelper.SetAuthCookies(
                httpContext.Response,
                _configuration,
                refreshResult.Data.Token,
                refreshResult.Data.ExpiresAt,
                refreshResult.Data.RefreshToken,
                refreshResult.Data.RefreshTokenExpiresAt,
                rememberMe);

            httpContext.Items["RefreshedAccessToken"] = refreshResult.Data.Token;
            return true;
        }

        private static string? GetAccessToken(HttpRequest request)
        {
            if (request.HttpContext.Items.TryGetValue("RefreshedAccessToken", out var refreshed)
                && refreshed is string refreshedToken
                && !string.IsNullOrWhiteSpace(refreshedToken))
            {
                return refreshedToken;
            }

            return request.Cookies.TryGetValue(AuthCookieHelper.AccessTokenCookieName, out var token)
                ? token
                : null;
        }

        private void TryAttachUserIdentity(HttpContext httpContext)
        {
            try
            {
                var token = GetAccessToken(httpContext.Request);
                if (string.IsNullOrWhiteSpace(token))
                {
                    return;
                }

                var principal = _jwtHelper.ValidateToken(token);
                if (principal == null)
                {
                    return;
                }

                httpContext.User = principal;
                var userInfo = _jwtHelper.ExtractUserInfo(principal);
                if (userInfo != null)
                {
                    httpContext.Items["UserInfo"] = userInfo;
                }
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "TryAttachUserIdentity failed (best-effort).");
            }
        }

        private void RedirectToLogin(AuthorizationFilterContext context)
        {
            var returnUrl = context.HttpContext.Request.Path + context.HttpContext.Request.QueryString;
            context.Result = new RedirectToActionResult(
                "Login",
                "Account",
                new { returnUrl });
        }

        private static bool IsAllowedPath(string path)
        {
            return AllowedPaths.Any(allowedPath =>
                path.StartsWith(allowedPath, StringComparison.OrdinalIgnoreCase));
        }
    }
}
