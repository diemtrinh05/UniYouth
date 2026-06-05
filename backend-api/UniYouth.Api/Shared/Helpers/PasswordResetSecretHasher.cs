using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.WebUtilities;

namespace UniYouth.Api.Shared.Helpers
{
    public static class PasswordResetSecretHasher
    {
        public static string Hash(string rawSecret)
        {
            var normalizedSecret = (rawSecret ?? string.Empty).Trim();
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(normalizedSecret));
            return WebEncoders.Base64UrlEncode(bytes);
        }
    }
}
