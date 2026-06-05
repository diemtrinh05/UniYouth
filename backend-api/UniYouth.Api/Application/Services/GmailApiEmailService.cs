using System.Text;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Auth.OAuth2.Flows;
using Google.Apis.Auth.OAuth2.Responses;
using Google.Apis.Gmail.v1;
using Google.Apis.Gmail.v1.Data;
using Google.Apis.Services;

namespace UniYouth.Api.Application.Services
{
    /// <summary>
    /// Gửi email qua Gmail API (OAuth2) cho Gmail cá nhân.
    /// Không cần App Password. Cần cấu hình ClientId/ClientSecret/RefreshToken.
    /// </summary>
    public sealed class GmailApiEmailService : IEmailService
    {
        private static readonly string[] Scopes = { GmailService.Scope.GmailSend };

        private readonly IConfiguration _configuration;
        private readonly ILogger<GmailApiEmailService> _logger;

        public GmailApiEmailService(IConfiguration configuration, ILogger<GmailApiEmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendAsync(string toEmail, string subject, string htmlBody, CancellationToken cancellationToken = default)
        {
            var enabled = _configuration.GetValue("Email:Gmail:Enabled", false);
            if (!enabled)
            {
                _logger.LogWarning("Gmail API chưa bật (Email:Gmail:Enabled=false). Bỏ qua gửi email.");
                return;
            }

            var clientId = _configuration["Email:Gmail:ClientId"];
            var clientSecret = _configuration["Email:Gmail:ClientSecret"];
            var refreshToken = _configuration["Email:Gmail:RefreshToken"];

            var fromEmail = _configuration["Email:From:Email"] ?? _configuration["Email:Gmail:UserEmail"];
            var fromName = _configuration["Email:From:Name"] ?? "UniYouth";

            if (string.IsNullOrWhiteSpace(clientId) ||
                string.IsNullOrWhiteSpace(clientSecret) ||
                string.IsNullOrWhiteSpace(refreshToken) ||
                string.IsNullOrWhiteSpace(fromEmail))
            {
                _logger.LogWarning("Thiếu cấu hình Gmail API (ClientId/ClientSecret/RefreshToken/FromEmail). Bỏ qua gửi email.");
                return;
            }

            var flow = new GoogleAuthorizationCodeFlow(new GoogleAuthorizationCodeFlow.Initializer
            {
                ClientSecrets = new ClientSecrets
                {
                    ClientId = clientId,
                    ClientSecret = clientSecret
                },
                Scopes = Scopes
            });

            var token = new TokenResponse
            {
                RefreshToken = refreshToken
            };

            // userId trong UserCredential chỉ là key định danh, không nhất thiết là email thật.
            var userId = fromEmail.Trim().ToLowerInvariant();
            var credential = new UserCredential(flow, userId, token);

            // Ensure access token (refresh if needed)
            await credential.GetAccessTokenForRequestAsync(cancellationToken: cancellationToken);

            var service = new GmailService(new BaseClientService.Initializer
            {
                HttpClientInitializer = credential,
                ApplicationName = "UniYouth.Api"
            });

            var rawMessage = BuildRawHtmlMessage(fromName, fromEmail, toEmail, subject, htmlBody);
            var msg = new Message { Raw = Base64UrlEncode(rawMessage) };

            await service.Users.Messages.Send(msg, "me").ExecuteAsync(cancellationToken);
        }

        private static string BuildRawHtmlMessage(string fromName, string fromEmail, string toEmail, string subject, string htmlBody)
        {
            static string EncodeHeader(string value)
                => "=?utf-8?B?" + Convert.ToBase64String(Encoding.UTF8.GetBytes(value)) + "?=";

            var sb = new StringBuilder();
            sb.AppendLine($"From: {EncodeHeader(fromName)} <{fromEmail}>");
            sb.AppendLine($"To: <{toEmail}>");
            sb.AppendLine($"Subject: {EncodeHeader(subject)}");
            sb.AppendLine("MIME-Version: 1.0");
            sb.AppendLine("Content-Type: text/html; charset=utf-8");
            sb.AppendLine("Content-Transfer-Encoding: 8bit");
            sb.AppendLine();
            sb.AppendLine(htmlBody);
            return sb.ToString();
        }

        private static string Base64UrlEncode(string input)
        {
            var bytes = Encoding.UTF8.GetBytes(input);
            return Convert.ToBase64String(bytes)
                .Replace('+', '-')
                .Replace('/', '_')
                .TrimEnd('=');
        }
    }
}

