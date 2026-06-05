using System.Net;
using Microsoft.AspNetCore.Http;

namespace UniYouth.Api.Shared.Helpers
{
    public static class ClientIpHelper
    {
        public static string? GetClientIpAddress(HttpContext httpContext)
        {
            var candidates = new[]
            {
                httpContext.Request.Headers["CF-Connecting-IP"].FirstOrDefault(),
                GetFirstForwardedFor(httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()),
                httpContext.Request.Headers["X-Real-IP"].FirstOrDefault(),
                httpContext.Connection.RemoteIpAddress?.ToString()
            };

            foreach (var candidate in candidates)
            {
                if (TryNormalizeIp(candidate, out var normalizedIp))
                {
                    return normalizedIp;
                }
            }

            return null;
        }

        private static string? GetFirstForwardedFor(string? forwardedFor)
        {
            if (string.IsNullOrWhiteSpace(forwardedFor))
            {
                return null;
            }

            return forwardedFor
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .FirstOrDefault();
        }

        private static bool TryNormalizeIp(string? rawIp, out string? normalizedIp)
        {
            normalizedIp = null;

            if (string.IsNullOrWhiteSpace(rawIp))
            {
                return false;
            }

            if (!IPAddress.TryParse(rawIp, out var parsedIp))
            {
                return false;
            }

            normalizedIp = parsedIp.ToString();
            return true;
        }
    }
}
