namespace UniYouth.Api.Application.Services
{
    public interface IPublicUrlBuilder
    {
        string? BuildAbsoluteUrl(string? relativeOrAbsoluteUrl);
    }

    public class PublicUrlBuilder : IPublicUrlBuilder
    {
        private readonly IConfiguration _configuration;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public PublicUrlBuilder(
            IConfiguration configuration,
            IHttpContextAccessor httpContextAccessor)
        {
            _configuration = configuration;
            _httpContextAccessor = httpContextAccessor;
        }

        public string? BuildAbsoluteUrl(string? relativeOrAbsoluteUrl)
        {
            if (string.IsNullOrWhiteSpace(relativeOrAbsoluteUrl))
            {
                return relativeOrAbsoluteUrl;
            }

            var configuredPublicBaseUrl = _configuration["PublicBaseUrl"];
            if (Uri.TryCreate(relativeOrAbsoluteUrl, UriKind.Absolute, out var absoluteUri))
            {
                if (!string.IsNullOrWhiteSpace(configuredPublicBaseUrl) && IsLocalOrPrivateAddress(absoluteUri.Host))
                {
                    return configuredPublicBaseUrl.TrimEnd('/') + absoluteUri.PathAndQuery;
                }

                return relativeOrAbsoluteUrl;
            }

            var baseUrl = string.IsNullOrWhiteSpace(configuredPublicBaseUrl)
                ? GetRequestBaseUrl()
                : configuredPublicBaseUrl;
            if (string.IsNullOrWhiteSpace(baseUrl))
            {
                return relativeOrAbsoluteUrl;
            }

            baseUrl = baseUrl.TrimEnd('/');
            var normalizedRelativeUrl = relativeOrAbsoluteUrl.StartsWith("/", StringComparison.Ordinal)
                ? relativeOrAbsoluteUrl
                : "/" + relativeOrAbsoluteUrl;

            return baseUrl + normalizedRelativeUrl;
        }

        private string? GetRequestBaseUrl()
        {
            var request = _httpContextAccessor.HttpContext?.Request;
            if (request == null || !request.Host.HasValue)
            {
                return null;
            }

            var forwardedProto = request.Headers["X-Forwarded-Proto"].FirstOrDefault();
            var forwardedHost = request.Headers["X-Forwarded-Host"].FirstOrDefault();

            var scheme = string.IsNullOrWhiteSpace(forwardedProto)
                ? request.Scheme
                : forwardedProto;

            var host = string.IsNullOrWhiteSpace(forwardedHost)
                ? request.Host.Value
                : forwardedHost;

            var pathBase = request.PathBase.HasValue
                ? request.PathBase.Value
                : string.Empty;

            return $"{scheme}://{host}{pathBase}";
        }

        private static bool IsLocalOrPrivateAddress(string host)
        {
            if (host.Equals("localhost", StringComparison.OrdinalIgnoreCase)
                || host.Equals("0.0.0.0", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            if (!System.Net.IPAddress.TryParse(host, out var ipAddress))
            {
                return false;
            }

            if (System.Net.IPAddress.IsLoopback(ipAddress))
            {
                return true;
            }

            var bytes = ipAddress.GetAddressBytes();
            return ipAddress.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork
                && (bytes[0] == 10
                    || (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31)
                    || (bytes[0] == 192 && bytes[1] == 168));
        }
    }
}
