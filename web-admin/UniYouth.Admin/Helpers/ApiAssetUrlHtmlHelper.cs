using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace UniYouth.Admin.Helpers
{
    public static class ApiAssetUrlHtmlHelper
    {
        public static string? ResolveApiAssetUrl(this IHtmlHelper html, string? url)
        {
            if (string.IsNullOrWhiteSpace(url)) return null;

            var configuration = html.ViewContext?.HttpContext?.RequestServices.GetService<IConfiguration>();
            var assetBaseUrl = ResolveAssetBaseUrl(configuration);
            var knownApiBaseUrls = ResolveKnownApiBaseUrls(configuration);

            if (url.StartsWith("data:", StringComparison.OrdinalIgnoreCase)) return url;
            if (Uri.TryCreate(url, UriKind.Absolute, out var absoluteUri))
            {
                if (string.IsNullOrWhiteSpace(assetBaseUrl))
                {
                    return url;
                }

                if (IsLocalOrPrivateAddress(absoluteUri.Host)
                    || IsKnownApiBaseUrl(absoluteUri, knownApiBaseUrls))
                {
                    return assetBaseUrl + absoluteUri.PathAndQuery;
                }

                return url;
            }

            var baseUrl = assetBaseUrl;
            var path = url.Replace('\\', '/').TrimStart('/');

            // Backend có thể trả về chỉ filename (vd: event_1025_xxx.jpg). Theo docs, ảnh event nằm trong /uploads/events/.
            if (!path.Contains('/') && path.Contains('.'))
            {
                path = "uploads/events/" + path;
            }
            if (string.IsNullOrWhiteSpace(baseUrl)) return "/" + path;

            return $"{baseUrl}/{path}";
        }

        private static string ResolveAssetBaseUrl(IConfiguration? configuration)
        {
            var configuredPublicBaseUrl =
                FirstNonEmpty(
                    configuration?["ApiSettings:AssetBaseUrl"],
                    configuration?["ApiSettings:PublicBaseUrl"],
                    configuration?["ApiSettings:BaseUrl"]);

            return configuredPublicBaseUrl.TrimEnd('/');
        }

        private static string[] ResolveKnownApiBaseUrls(IConfiguration? configuration)
        {
            return new[]
            {
                configuration?["ApiSettings:PublicBaseUrl"],
                configuration?["ApiSettings:BaseUrl"]
            }
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Select(value => value!.TrimEnd('/'))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
        }

        private static string FirstNonEmpty(params string?[] values)
        {
            foreach (var value in values)
            {
                if (!string.IsNullOrWhiteSpace(value))
                {
                    return value;
                }
            }

            return string.Empty;
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

        private static bool IsKnownApiBaseUrl(Uri absoluteUri, string[] knownApiBaseUrls)
        {
            foreach (var baseUrl in knownApiBaseUrls)
            {
                if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out var knownUri))
                {
                    continue;
                }

                if (absoluteUri.Scheme.Equals(knownUri.Scheme, StringComparison.OrdinalIgnoreCase)
                    && absoluteUri.Host.Equals(knownUri.Host, StringComparison.OrdinalIgnoreCase)
                    && absoluteUri.Port == knownUri.Port)
                {
                    return true;
                }
            }

            return false;
        }
    }
}
