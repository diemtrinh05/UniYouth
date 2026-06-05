using System.Security.Cryptography;
using Microsoft.AspNetCore.WebUtilities;

namespace UniYouth.Api.Shared.Helpers
{
    public static class TokenGenerator
    {
        public static string GenerateUrlSafeToken(int bytesLength = 32)
        {
            var bytes = RandomNumberGenerator.GetBytes(bytesLength);
            return WebEncoders.Base64UrlEncode(bytes);
        }
    }
}
