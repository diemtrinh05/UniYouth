using System.Net.Http.Headers;

namespace UniYouth.Admin.Services.Base
{
    public abstract class ApiClientBase
    {
        protected readonly HttpClient _httpClient;
        protected readonly IHttpContextAccessor _httpContextAccessor;

        protected const string AuthCookieName = "UniYouthAuth";

        protected ApiClientBase(HttpClient httpClient, IHttpContextAccessor accessor)
        {
            _httpClient = httpClient;
            _httpContextAccessor = accessor;
        }

        protected void AddAuthorizationHeader()
        {
            var context = _httpContextAccessor.HttpContext;

            if (context != null &&
                context.Request.Cookies.TryGetValue(AuthCookieName, out var token))
            {
                _httpClient.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", token);
            }
        }
    }
}
