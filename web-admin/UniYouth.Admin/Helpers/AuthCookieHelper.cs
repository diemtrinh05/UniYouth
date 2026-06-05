using Microsoft.AspNetCore.Http;

namespace UniYouth.Admin.Helpers
{
    public static class AuthCookieHelper
    {
        public const string AccessTokenCookieName = "UniYouthAuth";
        public const string RefreshTokenCookieName = "UniYouthRefresh";
        public const string RememberMeCookieName = "UniYouthRememberMe";

        public static void SetAuthCookies(
            HttpResponse response,
            IConfiguration configuration,
            string accessToken,
            DateTime accessTokenExpiresAt,
            string refreshToken,
            DateTime refreshTokenExpiresAt,
            bool rememberMe)
        {
            response.Cookies.Append(
                AccessTokenCookieName,
                accessToken,
                BuildCookieOptions(configuration, rememberMe ? accessTokenExpiresAt : null));

            response.Cookies.Append(
                RefreshTokenCookieName,
                refreshToken,
                BuildCookieOptions(configuration, rememberMe ? refreshTokenExpiresAt : null));

            response.Cookies.Append(
                RememberMeCookieName,
                rememberMe ? "1" : "0",
                BuildCookieOptions(configuration, rememberMe ? refreshTokenExpiresAt : null));
        }

        public static void DeleteAuthCookies(HttpResponse response, IConfiguration configuration)
        {
            var options = BuildCookieOptions(configuration, null);
            response.Cookies.Delete(AccessTokenCookieName, options);
            response.Cookies.Delete(RefreshTokenCookieName, options);
            response.Cookies.Delete(RememberMeCookieName, options);
        }

        public static bool IsRememberMeEnabled(HttpRequest request)
        {
            return request.Cookies.TryGetValue(RememberMeCookieName, out var raw)
                   && string.Equals(raw, "1", StringComparison.Ordinal);
        }

        private static CookieOptions BuildCookieOptions(IConfiguration configuration, DateTime? expiresAt)
        {
            return new CookieOptions
            {
                HttpOnly = true,
                Secure = configuration.GetValue<bool>("CookieSettings:Secure", true),
                SameSite = SameSiteMode.Strict,
                Path = "/",
                Expires = expiresAt,
                IsEssential = true
            };
        }
    }
}
