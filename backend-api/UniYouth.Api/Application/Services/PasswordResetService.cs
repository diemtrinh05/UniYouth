using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services
{
    public interface IPasswordResetService
    {
        Task RequestForgotPasswordAsync(string account, CancellationToken cancellationToken = default);
        Task<(bool Success, string Message)> ResetPasswordAsync(string token, string newPassword, CancellationToken cancellationToken = default);
    }

    public class PasswordResetService : IPasswordResetService
    {
        private const string PasswordResetPurpose = "PasswordReset";

        private readonly UniYouthDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IPublicUrlBuilder _publicUrlBuilder;
        private readonly IPasswordResetOtpService _passwordResetOtpService;
        private readonly IEmailService _emailService;
        private readonly ILogger<PasswordResetService> _logger;

        public PasswordResetService(
            UniYouthDbContext context,
            IConfiguration configuration,
            IPublicUrlBuilder publicUrlBuilder,
            IPasswordResetOtpService passwordResetOtpService,
            IEmailService emailService,
            ILogger<PasswordResetService> logger)
        {
            _context = context;
            _configuration = configuration;
            _publicUrlBuilder = publicUrlBuilder;
            _passwordResetOtpService = passwordResetOtpService;
            _emailService = emailService;
            _logger = logger;
        }

        public async Task RequestForgotPasswordAsync(string account, CancellationToken cancellationToken = default)
        {
            var normalizedAccount = NormalizeAccount(account);
            if (string.IsNullOrWhiteSpace(normalizedAccount))
            {
                return;
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Code == normalizedAccount, cancellationToken);

            if (user == null || user.Status != 1)
            {
                return;
            }

            var otpResult = await _passwordResetOtpService.IssueOtpAsync(
                user.UserID,
                PasswordResetPurpose,
                cancellationToken: cancellationToken);

            try
            {
                var subject = "UniYouth - Mã OTP đặt lại mật khẩu";
                var html = $@"
<p>Bạn vừa yêu cầu đặt lại mật khẩu cho tài khoản UniYouth.</p>
<p>Mã OTP của bạn là:</p>
<h2 style=""letter-spacing: 4px;"">{otpResult.OtpCode}</h2>
<p>Mã có hiệu lực trong <b>5 phút</b>.</p>
<p>Không chia sẻ mã này cho bất kỳ ai.</p>
<p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.</p>";

                await _emailService.SendAsync(user.Email, subject, html, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Gửi email OTP quên mật khẩu thất bại cho UserId {UserId}", user.UserID);
            }
        }

        public async Task<(bool Success, string Message)> ResetPasswordAsync(string token, string newPassword, CancellationToken cancellationToken = default)
        {
            var passwordValidation = PasswordStrengthValidator.Validate(newPassword);
            if (!passwordValidation.IsValid)
            {
                return (false, passwordValidation.ErrorMessage);
            }

            var now = DateTime.Now;
            var tokenHash = HashToken((token ?? string.Empty).Trim());

            var resetToken = await _context.PasswordResetTokens
                .Include(t => t.User)
                .FirstOrDefaultAsync(t => t.Token == tokenHash, cancellationToken);

            if (resetToken == null || resetToken.IsUsed || resetToken.ExpiredAt <= now)
            {
                return (false, "Token không hợp lệ hoặc đã hết hạn");
            }

            if (resetToken.User.Status != 1)
            {
                return (false, "Token không hợp lệ hoặc đã hết hạn");
            }

            resetToken.User.PasswordHash = PasswordHelper.HashPassword(newPassword);
            resetToken.User.UpdatedDate = now;
            resetToken.IsUsed = true;

            var otherTokens = await _context.PasswordResetTokens
                .Where(t => t.UserID == resetToken.UserID && !t.IsUsed && t.Id != resetToken.Id)
                .ToListAsync(cancellationToken);

            foreach (var item in otherTokens)
            {
                item.IsUsed = true;
            }

            await _context.SaveChangesAsync(cancellationToken);

            return (true, "Đặt lại mật khẩu thành công.");
        }

        private string BuildResetLink(string rawToken)
        {
            var path = _configuration["PasswordReset:ResetPath"] ?? "/reset-password";
            path = path.StartsWith('/') ? path : "/" + path;
            var pathWithQuery = $"{path}?token={Uri.EscapeDataString(rawToken)}";

            var configuredBaseUrl = _configuration["PasswordReset:PublicResetBaseUrl"];
            if (!string.IsNullOrWhiteSpace(configuredBaseUrl))
            {
                return Combine(configuredBaseUrl, pathWithQuery);
            }

            return _publicUrlBuilder.BuildAbsoluteUrl(pathWithQuery) ?? pathWithQuery;
        }

        private static string HashToken(string rawToken)
        {
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(rawToken));
            return WebEncoders.Base64UrlEncode(bytes);
        }

        private static string Combine(string baseUrl, string path)
        {
            var normalizedBaseUrl = baseUrl.TrimEnd('/');
            var normalizedPath = path.StartsWith("/", StringComparison.Ordinal)
                ? path
                : "/" + path;

            return normalizedBaseUrl + normalizedPath;
        }

        private static string NormalizeAccount(string account)
        {
            return (account ?? string.Empty).Trim();
        }
    }
}










