using System.Net;
using System.Net.Mail;
using System.Text;

namespace UniYouth.Api.Application.Services
{
    public interface IEmailService
    {
        Task SendAsync(string toEmail, string subject, string htmlBody, CancellationToken cancellationToken = default);
    }

    public class SmtpEmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<SmtpEmailService> _logger;

        public SmtpEmailService(IConfiguration configuration, ILogger<SmtpEmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendAsync(string toEmail, string subject, string htmlBody, CancellationToken cancellationToken = default)
        {
            var host = _configuration["Email:Smtp:Host"];
            if (string.IsNullOrWhiteSpace(host))
            {
                _logger.LogWarning("Email SMTP Host chưa được cấu hình (Email:Smtp:Host). Bỏ qua gửi email.");
                return;
            }

            var port = _configuration.GetValue("Email:Smtp:Port", 587);
            var enableSsl = _configuration.GetValue("Email:Smtp:EnableSsl", true);
            var username = _configuration["Email:Smtp:Username"];
            var password = _configuration["Email:Smtp:Password"];
            var fromEmail = _configuration["Email:From:Email"] ?? username;
            var fromName = _configuration["Email:From:Name"] ?? "UniYouth";

            if (string.IsNullOrWhiteSpace(fromEmail))
            {
                _logger.LogWarning("Email From chưa được cấu hình (Email:From:Email hoặc Email:Smtp:Username). Bỏ qua gửi email.");
                return;
            }

            using var client = new SmtpClient(host, port)
            {
                EnableSsl = enableSsl,
                DeliveryMethod = SmtpDeliveryMethod.Network
            };

            if (!string.IsNullOrWhiteSpace(username))
            {
                client.Credentials = new NetworkCredential(username, password);
            }

            using var message = new MailMessage
            {
                From = new MailAddress(fromEmail, fromName),
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true,
                SubjectEncoding = Encoding.UTF8,
                BodyEncoding = Encoding.UTF8,
                HeadersEncoding = Encoding.UTF8
            };
            message.To.Add(new MailAddress(toEmail));

            await client.SendMailAsync(message, cancellationToken);
        }
    }
}
