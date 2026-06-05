using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Net;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text.Json;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.PushNotifications;

namespace UniYouth.Api.Application.Services
{
    public sealed record PushMessage(
        string Title,
        string Body,
        IDictionary<string, string>? Data = null);

    public interface IPushNotificationService
    {
        Task SendToUserAsync(int userId, PushMessage message, CancellationToken cancellationToken);
    }

    public sealed class PushNotificationService : IPushNotificationService
    {
        private static readonly string[] FcmScopes = { "https://www.googleapis.com/auth/firebase.messaging" };
        private const int MaxRetryAttempts = 3;

        private readonly UniYouthDbContext _context;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IDeviceTokenService _deviceTokenService;
        private readonly PushNotificationOptions _options;
        private readonly ILogger<PushNotificationService> _logger;

        public PushNotificationService(
            UniYouthDbContext context,
            IHttpClientFactory httpClientFactory,
            IDeviceTokenService deviceTokenService,
            IOptions<PushNotificationOptions> options,
            ILogger<PushNotificationService> logger)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
            _deviceTokenService = deviceTokenService;
            _options = options.Value;
            _logger = logger;
        }

        public async Task SendToUserAsync(int userId, PushMessage message, CancellationToken cancellationToken)
        {
            var tokens = await _context.UserDeviceTokens
                .Where(t => t.UserID == userId && t.IsActive)
                .Select(t => new
                {
                    t.UserDeviceTokenID,
                    t.Platform,
                    t.Token
                })
                .ToListAsync(cancellationToken);

            if (tokens.Count == 0)
            {
                return;
            }

            var successCount = 0;
            var transientFailures = new List<string>();

            foreach (var token in tokens)
            {
                var result = await SendWithRetryAsync(
                    token.Platform,
                    token.Token,
                    message,
                    cancellationToken);

                if (result.IsSuccess)
                {
                    successCount++;
                    continue;
                }

                if (result.IsPermanentFailure)
                {
                    await _deviceTokenService.MarkTokenAsInvalidAsync(
                        token.UserDeviceTokenID,
                        result.ErrorMessage,
                        cancellationToken);
                    continue;
                }

                transientFailures.Add(
                    $"TokenId={token.UserDeviceTokenID}, Platform={token.Platform}, Error={result.ErrorMessage}");
            }

            if (successCount > 0)
            {
                return;
            }

            if (transientFailures.Count == 0)
            {
                _logger.LogInformation(
                    "Push skipped do tất cả token đã bị vô hiệu hóa/permanent failure. UserId={UserId}",
                    userId);
                return;
            }

            throw new InvalidOperationException(
                $"Push delivery transient failure cho UserId={userId}. {string.Join(" | ", transientFailures.Take(3))}");
        }

        private async Task<PushDispatchResult> SendWithRetryAsync(
            string platform,
            string deviceToken,
            PushMessage message,
            CancellationToken cancellationToken)
        {
            PushDispatchResult? lastResult = null;

            for (var attempt = 1; attempt <= MaxRetryAttempts; attempt++)
            {
                try
                {
                    lastResult = await SendOnceAsync(platform, deviceToken, message, cancellationToken);
                }
                catch (Exception ex)
                {
                    lastResult = PushDispatchResult.TransientFailure(ex.Message);
                }

                if (lastResult.IsSuccess || lastResult.IsPermanentFailure)
                {
                    return lastResult;
                }

                if (attempt < MaxRetryAttempts)
                {
                    await Task.Delay(GetRetryDelay(attempt), cancellationToken);
                }
            }

            return lastResult ?? PushDispatchResult.TransientFailure("Unknown push failure.");
        }

        private Task<PushDispatchResult> SendOnceAsync(
            string platform,
            string deviceToken,
            PushMessage message,
            CancellationToken cancellationToken)
        {
            if (platform.Equals("Fcm", StringComparison.OrdinalIgnoreCase))
            {
                return SendFcmAsync(deviceToken, message, cancellationToken);
            }

            if (platform.Equals("Apns", StringComparison.OrdinalIgnoreCase))
            {
                return SendApnsAsync(deviceToken, message, cancellationToken);
            }

            return Task.FromResult(PushDispatchResult.PermanentFailure($"Unsupported push platform: {platform}"));
        }

        private async Task<PushDispatchResult> SendFcmAsync(string deviceToken, PushMessage message, CancellationToken cancellationToken)
        {
            if (!_options.Fcm.Enabled)
            {
                _logger.LogInformation("FCM dispatch skipped because FCM is disabled.");
                return PushDispatchResult.Success();
            }

            if (string.IsNullOrWhiteSpace(_options.Fcm.ProjectId))
            {
                _logger.LogWarning("FCM enabled nhưng thiếu cấu hình ProjectId.");
                return PushDispatchResult.PermanentFailure("FCM is enabled but ProjectId is missing.");
            }

            GoogleCredential credential;
            try
            {
                credential = CreateFcmCredential();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "FCM enabled nhưng chưa có credential hợp lệ.");
                return PushDispatchResult.PermanentFailure(ex.Message);
            }

            var accessToken = await credential.UnderlyingCredential
                .GetAccessTokenForRequestAsync(cancellationToken: cancellationToken);

            var http = _httpClientFactory.CreateClient("push.fcm");
            http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            var url = $"https://fcm.googleapis.com/v1/projects/{_options.Fcm.ProjectId}/messages:send";
            var payload = new
            {
                message = new
                {
                    token = deviceToken,
                    notification = new
                    {
                        title = message.Title,
                        body = message.Body
                    },
                    data = message.Data
                }
            };

            var res = await http.PostAsJsonAsync(url, payload, cancellationToken);
            if (res.IsSuccessStatusCode)
            {
                return PushDispatchResult.Success();
            }

            var body = await res.Content.ReadAsStringAsync(cancellationToken);
            var reason = ExtractFcmErrorReason(body);

            if (IsFcmInvalidToken(res.StatusCode, reason, body))
            {
                _logger.LogInformation(
                    "FCM báo token không hợp lệ. Status={Status}, Reason={Reason}",
                    (int)res.StatusCode,
                    reason);
                return PushDispatchResult.PermanentFailure($"FCM invalid token: {reason ?? body}");
            }

            if (IsTransientStatusCode(res.StatusCode))
            {
                return PushDispatchResult.TransientFailure($"FCM transient error {(int)res.StatusCode}: {reason ?? body}");
            }

            return PushDispatchResult.PermanentFailure($"FCM permanent error {(int)res.StatusCode}: {reason ?? body}");
        }

        private GoogleCredential CreateFcmCredential()
        {
            if (!string.IsNullOrWhiteSpace(_options.Fcm.ServiceAccountJson))
            {
                return GoogleCredential
                    .FromJson(_options.Fcm.ServiceAccountJson)
                    .CreateScoped(FcmScopes);
            }

            if (string.IsNullOrWhiteSpace(_options.Fcm.ServiceAccountJsonPath))
            {
                throw new InvalidOperationException(
                    "FCM is enabled but ServiceAccountJsonPath/ServiceAccountJson is missing.");
            }

            if (!File.Exists(_options.Fcm.ServiceAccountJsonPath))
            {
                throw new FileNotFoundException(
                    $"FCM service account file not found: {_options.Fcm.ServiceAccountJsonPath}",
                    _options.Fcm.ServiceAccountJsonPath);
            }

            return GoogleCredential
                .FromFile(_options.Fcm.ServiceAccountJsonPath)
                .CreateScoped(FcmScopes);
        }

        private async Task<PushDispatchResult> SendApnsAsync(string deviceToken, PushMessage message, CancellationToken cancellationToken)
        {
            if (!_options.Apns.Enabled)
            {
                return PushDispatchResult.Success();
            }

            if (string.IsNullOrWhiteSpace(_options.Apns.TeamId) ||
                string.IsNullOrWhiteSpace(_options.Apns.KeyId) ||
                string.IsNullOrWhiteSpace(_options.Apns.BundleId) ||
                string.IsNullOrWhiteSpace(_options.Apns.PrivateKeyPath))
            {
                _logger.LogWarning("APNS enabled nhưng thiếu cấu hình TeamId/KeyId/BundleId/PrivateKeyPath");
                return PushDispatchResult.Success();
            }

            var jwt = CreateApnsJwt(_options.Apns.TeamId, _options.Apns.KeyId, _options.Apns.PrivateKeyPath);
            var host = _options.Apns.UseSandbox ? "https://api.sandbox.push.apple.com" : "https://api.push.apple.com";
            var url = $"{host}/3/device/{deviceToken}";

            var http = _httpClientFactory.CreateClient("push.apns");
            using var req = new HttpRequestMessage(HttpMethod.Post, url);
            req.Version = new Version(2, 0);
            req.Headers.Authorization = new AuthenticationHeaderValue("bearer", jwt);
            req.Headers.TryAddWithoutValidation("apns-topic", _options.Apns.BundleId);

            var apnsPayload = new
            {
                aps = new
                {
                    alert = new { title = message.Title, body = message.Body },
                    sound = "default"
                },
                data = message.Data
            };

            req.Content = JsonContent.Create(apnsPayload);

            var res = await http.SendAsync(req, cancellationToken);
            if (res.IsSuccessStatusCode)
            {
                return PushDispatchResult.Success();
            }

            var body = await res.Content.ReadAsStringAsync(cancellationToken);
            var reason = ExtractApnsReason(body);

            if (IsApnsInvalidToken(res.StatusCode, reason))
            {
                _logger.LogInformation(
                    "APNS báo token không hợp lệ. Status={Status}, Reason={Reason}",
                    (int)res.StatusCode,
                    reason);
                return PushDispatchResult.PermanentFailure($"APNS invalid token: {reason ?? body}");
            }

            if (IsTransientStatusCode(res.StatusCode))
            {
                return PushDispatchResult.TransientFailure($"APNS transient error {(int)res.StatusCode}: {reason ?? body}");
            }

            return PushDispatchResult.PermanentFailure($"APNS permanent error {(int)res.StatusCode}: {reason ?? body}");
        }

        private static string CreateApnsJwt(string teamId, string keyId, string privateKeyPath)
        {
            var privateKeyPem = File.ReadAllText(privateKeyPath);
            var pkcs8 = ReadPkcs8FromPem(privateKeyPem);

            using var ecdsa = ECDsa.Create();
            ecdsa.ImportPkcs8PrivateKey(pkcs8, out _);

            var securityKey = new ECDsaSecurityKey(ecdsa) { KeyId = keyId };
            var creds = new SigningCredentials(securityKey, SecurityAlgorithms.EcdsaSha256);

            var now = DateTimeOffset.UtcNow;
            var token = new JwtSecurityToken(
                issuer: teamId,
                audience: null,
                claims: null,
                notBefore: now.UtcDateTime,
                expires: now.AddMinutes(50).UtcDateTime,
                signingCredentials: creds);

            token.Header["kid"] = keyId;

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private static byte[] ReadPkcs8FromPem(string pem)
        {
            const string header = "-----BEGIN PRIVATE KEY-----";
            const string footer = "-----END PRIVATE KEY-----";

            var start = pem.IndexOf(header, StringComparison.Ordinal);
            var end = pem.IndexOf(footer, StringComparison.Ordinal);
            if (start < 0 || end < 0 || end <= start)
            {
                throw new InvalidOperationException("APNS private key PEM không hợp lệ");
            }

            var base64 = pem
                .Substring(start + header.Length, end - (start + header.Length))
                .Replace("\r", string.Empty)
                .Replace("\n", string.Empty)
                .Trim();

            return Convert.FromBase64String(base64);
        }

        private static bool IsTransientStatusCode(HttpStatusCode statusCode)
        {
            var code = (int)statusCode;
            return code == 408 || code == 429 || code >= 500;
        }

        private static bool IsFcmInvalidToken(HttpStatusCode statusCode, string? reason, string? body)
        {
            if (statusCode == HttpStatusCode.NotFound)
            {
                return true;
            }

            return ContainsAny(reason, "UNREGISTERED", "INVALID_ARGUMENT")
                || ContainsAny(body, "UNREGISTERED", "registration-token-not-registered", "invalid-registration-token");
        }

        private static bool IsApnsInvalidToken(HttpStatusCode statusCode, string? reason)
        {
            if (statusCode == HttpStatusCode.Gone || statusCode == HttpStatusCode.NotFound)
            {
                return true;
            }

            return ContainsAny(reason, "BadDeviceToken", "Unregistered", "DeviceTokenNotForTopic");
        }

        private static string? ExtractApnsReason(string body)
        {
            try
            {
                using var document = JsonDocument.Parse(body);
                if (document.RootElement.TryGetProperty("reason", out var reasonElement))
                {
                    return reasonElement.GetString();
                }
            }
            catch
            {
                // Ignore parse errors, fallback raw body.
            }

            return null;
        }

        private static string? ExtractFcmErrorReason(string body)
        {
            try
            {
                using var document = JsonDocument.Parse(body);

                if (document.RootElement.TryGetProperty("error", out var errorElement))
                {
                    if (errorElement.TryGetProperty("status", out var statusElement))
                    {
                        var status = statusElement.GetString();
                        if (!string.IsNullOrWhiteSpace(status))
                        {
                            return status;
                        }
                    }

                    if (errorElement.TryGetProperty("message", out var messageElement))
                    {
                        var errMessage = messageElement.GetString();
                        if (!string.IsNullOrWhiteSpace(errMessage))
                        {
                            return errMessage;
                        }
                    }

                    if (errorElement.TryGetProperty("details", out var detailsElement) &&
                        detailsElement.ValueKind == JsonValueKind.Array)
                    {
                        foreach (var detail in detailsElement.EnumerateArray())
                        {
                            if (detail.TryGetProperty("errorCode", out var errorCodeElement))
                            {
                                var errorCode = errorCodeElement.GetString();
                                if (!string.IsNullOrWhiteSpace(errorCode))
                                {
                                    return errorCode;
                                }
                            }
                        }
                    }
                }
            }
            catch
            {
                // Ignore parse errors, fallback raw body.
            }

            return null;
        }

        private static bool ContainsAny(string? source, params string[] keywords)
        {
            if (string.IsNullOrWhiteSpace(source))
            {
                return false;
            }

            return keywords.Any(keyword =>
                source.Contains(keyword, StringComparison.OrdinalIgnoreCase));
        }

        private static TimeSpan GetRetryDelay(int attempt)
        {
            var seconds = Math.Clamp(attempt * 2, 2, 8);
            return TimeSpan.FromSeconds(seconds);
        }

        private sealed record PushDispatchResult(
            bool IsSuccess,
            bool IsPermanentFailure,
            string? ErrorMessage)
        {
            public static PushDispatchResult Success() => new(true, false, null);
            public static PushDispatchResult TransientFailure(string message) => new(false, false, message);
            public static PushDispatchResult PermanentFailure(string message) => new(false, true, message);
        }
    }
}


