using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services
{
    public sealed class PasswordResetOtpIssueResult
    {
        public int OtpId { get; init; }

        public string OtpCode { get; init; } = string.Empty;

        public string Purpose { get; init; } = string.Empty;

        public DateTime ExpiresAt { get; init; }
    }

    public sealed class PasswordResetOtpVerifyResult
    {
        public bool Success { get; init; }

        public int? OtpId { get; init; }

        public string Message { get; init; } = string.Empty;

        public DateTime? VerifiedAt { get; init; }
    }

    public sealed class PasswordResetSessionIssueResult
    {
        public bool Success { get; init; }

        public int? ResetSessionId { get; init; }

        public string Message { get; init; } = string.Empty;

        public string? VerificationTicket { get; init; }

        public DateTime? ExpiresAt { get; init; }
    }

    public sealed class PasswordResetWithVerificationTicketResult
    {
        public bool Success { get; init; }

        public string Message { get; init; } = string.Empty;
    }

    public interface IPasswordResetOtpService
    {
        Task<PasswordResetOtpIssueResult> IssueOtpAsync(
            int userId,
            string purpose,
            string? requestIp = null,
            string? requestUserAgent = null,
            CancellationToken cancellationToken = default);

        Task<int> RevokeActiveOtpsAsync(
            int userId,
            string purpose,
            CancellationToken cancellationToken = default);

        Task<PasswordResetOtpVerifyResult> VerifyOtpAsync(
            int userId,
            string purpose,
            string otpCode,
            CancellationToken cancellationToken = default);

        Task<PasswordResetSessionIssueResult> VerifyResetOtpAsync(
            string account,
            string otpCode,
            CancellationToken cancellationToken = default);

        Task<PasswordResetSessionIssueResult> IssueVerificationTicketAsync(
            int userId,
            int otpId,
            CancellationToken cancellationToken = default);

        Task<PasswordResetWithVerificationTicketResult> ResetPasswordWithVerificationTicketAsync(
            string verificationTicket,
            string newPassword,
            CancellationToken cancellationToken = default);
    }

    public class PasswordResetOtpService : IPasswordResetOtpService
    {
        private const string PasswordResetPurpose = "PasswordReset";
        private const int OtpExpireMinutes = 5;
        private const int OtpMaxAttempts = 5;
        private const int OtpMaxResends = 3;
        private const int ResetSessionExpireMinutes = 5;

        private readonly UniYouthDbContext _context;
        private readonly ILogger<PasswordResetOtpService> _logger;

        public PasswordResetOtpService(
            UniYouthDbContext context,
            ILogger<PasswordResetOtpService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<PasswordResetOtpIssueResult> IssueOtpAsync(
            int userId,
            string purpose,
            string? requestIp = null,
            string? requestUserAgent = null,
            CancellationToken cancellationToken = default)
        {
            if (userId <= 0)
            {
                throw new InvalidOperationException("UserID không hợp lệ");
            }

            var normalizedPurpose = NormalizePurpose(purpose);
            var now = DateTime.Now;
            var expiresAt = now.AddMinutes(OtpExpireMinutes);

            var revokedCount = await RevokeActiveOtpsInternalAsync(userId, normalizedPurpose, now, cancellationToken);

            var rawOtp = GenerateOtpCode();
            var otpHash = PasswordResetSecretHasher.Hash(rawOtp);

            var otp = new Domain.Entities.PasswordResetOtp
            {
                UserID = userId,
                OtpHash = otpHash,
                Purpose = normalizedPurpose,
                ExpiresAt = expiresAt,
                AttemptCount = 0,
                MaxAttempts = OtpMaxAttempts,
                ResendCount = 0,
                MaxResends = OtpMaxResends,
                IsUsed = false,
                CreatedDate = now,
                LastSentAt = now,
                RequestIp = NormalizeRequestIp(requestIp),
                RequestUserAgent = NormalizeRequestUserAgent(requestUserAgent)
            };

            _context.PasswordResetOtps.Add(otp);
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Issued OTP {OtpId} for UserId {UserId}, Purpose {Purpose}, ExpiresAt {ExpiresAt}, RevokedCount {RevokedCount}",
                otp.OtpID,
                userId,
                normalizedPurpose,
                expiresAt,
                revokedCount);

            return new PasswordResetOtpIssueResult
            {
                OtpId = otp.OtpID,
                OtpCode = rawOtp,
                Purpose = normalizedPurpose,
                ExpiresAt = expiresAt
            };
        }

        public async Task<int> RevokeActiveOtpsAsync(
            int userId,
            string purpose,
            CancellationToken cancellationToken = default)
        {
            if (userId <= 0)
            {
                throw new InvalidOperationException("UserID không hợp lệ");
            }

            var normalizedPurpose = NormalizePurpose(purpose);
            var now = DateTime.Now;
            var revokedCount = await RevokeActiveOtpsInternalAsync(userId, normalizedPurpose, now, cancellationToken);

            if (revokedCount > 0)
            {
                _logger.LogInformation(
                    "Revoked {RevokedCount} active OTP(s) for UserId {UserId}, Purpose {Purpose}",
                    revokedCount,
                    userId,
                    normalizedPurpose);
            }

            return revokedCount;
        }

        public async Task<PasswordResetOtpVerifyResult> VerifyOtpAsync(
            int userId,
            string purpose,
            string otpCode,
            CancellationToken cancellationToken = default)
        {
            if (userId <= 0)
            {
                throw new InvalidOperationException("UserID không hợp lệ");
            }

            var normalizedPurpose = NormalizePurpose(purpose);
            var normalizedOtpCode = NormalizeOtpCode(otpCode);
            var now = DateTime.Now;

            var otp = await _context.PasswordResetOtps
                .Where(item => item.UserID == userId
                    && item.Purpose == normalizedPurpose
                    && !item.IsUsed
                    && item.RevokedAt == null)
                .OrderByDescending(item => item.CreatedDate)
                .FirstOrDefaultAsync(cancellationToken);

            if (otp == null)
            {
                _logger.LogWarning(
                    "OTP verification failed because no active OTP was found for UserId {UserId}, Purpose {Purpose}",
                    userId,
                    normalizedPurpose);

                return CreateFailedVerifyResult("OTP không hợp lệ hoặc đã hết hạn.");
            }

            if (otp.ExpiresAt <= now)
            {
                otp.IsUsed = true;
                otp.RevokedAt = now;
                await _context.SaveChangesAsync(cancellationToken);

                _logger.LogWarning(
                    "OTP verification failed because OTP {OtpId} expired for UserId {UserId}, Purpose {Purpose}",
                    otp.OtpID,
                    userId,
                    normalizedPurpose);

                return CreateFailedVerifyResult("OTP không hợp lệ hoặc đã hết hạn.");
            }

            if (otp.AttemptCount >= otp.MaxAttempts)
            {
                otp.IsUsed = true;
                otp.RevokedAt = otp.RevokedAt ?? now;
                await _context.SaveChangesAsync(cancellationToken);

                _logger.LogWarning(
                    "OTP verification blocked because OTP {OtpId} exceeded max attempts for UserId {UserId}, Purpose {Purpose}",
                    otp.OtpID,
                    userId,
                    normalizedPurpose);

                return CreateFailedVerifyResult("OTP đã vượt quá số lần thử cho phép.");
            }

            var otpHash = PasswordResetSecretHasher.Hash(normalizedOtpCode);
            if (!string.Equals(otp.OtpHash, otpHash, StringComparison.Ordinal))
            {
                otp.AttemptCount += 1;
                if (otp.AttemptCount >= otp.MaxAttempts)
                {
                    otp.IsUsed = true;
                    otp.RevokedAt = now;
                }

                await _context.SaveChangesAsync(cancellationToken);

                _logger.LogWarning(
                    "OTP verification failed for OTP {OtpId}, UserId {UserId}, Purpose {Purpose}, AttemptCount {AttemptCount}/{MaxAttempts}",
                    otp.OtpID,
                    userId,
                    normalizedPurpose,
                    otp.AttemptCount,
                    otp.MaxAttempts);

                return CreateFailedVerifyResult(
                    otp.IsUsed
                        ? "OTP đã vượt quá số lần thử cho phép."
                        : "OTP không chính xác.");
            }

            otp.VerifiedAt = now;
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "OTP {OtpId} verified successfully for UserId {UserId}, Purpose {Purpose} at {VerifiedAt}",
                otp.OtpID,
                userId,
                normalizedPurpose,
                now);

            return new PasswordResetOtpVerifyResult
            {
                Success = true,
                OtpId = otp.OtpID,
                Message = "Xác thực OTP thành công.",
                VerifiedAt = now
            };
        }

        public async Task<PasswordResetSessionIssueResult> VerifyResetOtpAsync(
            string account,
            string otpCode,
            CancellationToken cancellationToken = default)
        {
            var normalizedAccount = NormalizeAccount(account);
            if (string.IsNullOrWhiteSpace(normalizedAccount))
            {
                _logger.LogWarning("Reset OTP verification failed because account was empty.");
                return CreateFailedSessionIssueResult("OTP không hợp lệ hoặc đã hết hạn.");
            }

            var user = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    item => item.Code == normalizedAccount && item.Status == 1,
                    cancellationToken);

            if (user == null)
            {
                _logger.LogWarning("Reset OTP verification rejected because no eligible active user was found.");
                return CreateFailedSessionIssueResult("OTP không hợp lệ hoặc đã hết hạn.");
            }

            var verifyResult = await VerifyOtpAsync(user.UserID, PasswordResetPurpose, otpCode, cancellationToken);
            if (!verifyResult.Success || !verifyResult.OtpId.HasValue)
            {
                _logger.LogWarning(
                    "Reset OTP verification failed for UserId {UserId}: {Message}",
                    user.UserID,
                    verifyResult.Message);

                return CreateFailedSessionIssueResult(verifyResult.Message);
            }

            var sessionResult = await IssueVerificationTicketAsync(user.UserID, verifyResult.OtpId.Value, cancellationToken);
            if (sessionResult.Success)
            {
                _logger.LogInformation(
                    "Reset verification ticket {ResetSessionId} issued for UserId {UserId} after OTP verification",
                    sessionResult.ResetSessionId,
                    user.UserID);
            }
            else
            {
                _logger.LogWarning(
                    "Reset verification ticket issuance failed for UserId {UserId}: {Message}",
                    user.UserID,
                    sessionResult.Message);
            }

            return sessionResult;
        }

        public async Task<PasswordResetSessionIssueResult> IssueVerificationTicketAsync(
            int userId,
            int otpId,
            CancellationToken cancellationToken = default)
        {
            if (userId <= 0)
            {
                throw new InvalidOperationException("UserID không hợp lệ");
            }

            if (otpId <= 0)
            {
                throw new InvalidOperationException("OtpID không hợp lệ");
            }

            var now = DateTime.Now;

            var otp = await _context.PasswordResetOtps
                .FirstOrDefaultAsync(
                    item => item.OtpID == otpId,
                    cancellationToken);

            if (otp == null || otp.UserID != userId)
            {
                _logger.LogWarning(
                    "Verification ticket issuance failed because OTP {OtpId} was not found for UserId {UserId}",
                    otpId,
                    userId);

                return CreateFailedSessionIssueResult("OTP không hợp lệ hoặc đã hết hạn.");
            }

            if (otp.IsUsed || otp.RevokedAt != null || otp.ExpiresAt <= now)
            {
                _logger.LogWarning(
                    "Verification ticket issuance failed because OTP {OtpId} is no longer active for UserId {UserId}",
                    otpId,
                    userId);

                return CreateFailedSessionIssueResult("OTP không hợp lệ hoặc đã hết hạn.");
            }

            if (otp.VerifiedAt == null)
            {
                _logger.LogWarning(
                    "Verification ticket issuance failed because OTP {OtpId} has not been verified for UserId {UserId}",
                    otpId,
                    userId);

                return CreateFailedSessionIssueResult("OTP chưa được xác thực.");
            }

            var activeSessions = await _context.PasswordResetSessions
                .Where(session => session.UserID == userId
                    && !session.IsUsed
                    && session.ExpiresAt > now)
                .ToListAsync(cancellationToken);

            foreach (var session in activeSessions)
            {
                session.IsUsed = true;
                session.UsedAt = now;
            }

            var rawVerificationTicket = TokenGenerator.GenerateUrlSafeToken(32);
            var verificationTicketHash = PasswordResetSecretHasher.Hash(rawVerificationTicket);
            var expiresAt = now.AddMinutes(ResetSessionExpireMinutes);

            var resetSession = new Domain.Entities.PasswordResetSession
            {
                UserID = userId,
                OtpID = otpId,
                SessionTokenHash = verificationTicketHash,
                ExpiresAt = expiresAt,
                IsUsed = false,
                CreatedDate = now
            };

            _context.PasswordResetSessions.Add(resetSession);
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Issued reset verification ticket session {ResetSessionId} for UserId {UserId}, OtpId {OtpId}, ExpiresAt {ExpiresAt}, RevokedSessions {RevokedSessions}",
                resetSession.ResetSessionID,
                userId,
                otpId,
                expiresAt,
                activeSessions.Count);

            return new PasswordResetSessionIssueResult
            {
                Success = true,
                ResetSessionId = resetSession.ResetSessionID,
                Message = "Cấp verification ticket thành công.",
                VerificationTicket = rawVerificationTicket,
                ExpiresAt = expiresAt
            };
        }

        public async Task<PasswordResetWithVerificationTicketResult> ResetPasswordWithVerificationTicketAsync(
            string verificationTicket,
            string newPassword,
            CancellationToken cancellationToken = default)
        {
            var normalizedVerificationTicket = NormalizeVerificationTicket(verificationTicket);
            var passwordValidation = PasswordStrengthValidator.Validate(newPassword);
            if (!passwordValidation.IsValid)
            {
                _logger.LogWarning("Password reset via verification ticket rejected because new password did not pass validation.");
                return CreateFailedPasswordResetResult(passwordValidation.ErrorMessage);
            }

            var now = DateTime.Now;
            var verificationTicketHash = PasswordResetSecretHasher.Hash(normalizedVerificationTicket);

            var resetSession = await _context.PasswordResetSessions
                .Include(session => session.User)
                .Include(session => session.Otp)
                .FirstOrDefaultAsync(
                    session => session.SessionTokenHash == verificationTicketHash,
                    cancellationToken);

            if (resetSession == null || resetSession.IsUsed || resetSession.ExpiresAt <= now)
            {
                _logger.LogWarning("Password reset via verification ticket failed because the session was invalid or expired.");
                return CreateFailedPasswordResetResult("Verification ticket không hợp lệ hoặc đã hết hạn.");
            }

            if (resetSession.Otp == null
                || resetSession.Otp.IsUsed
                || resetSession.Otp.RevokedAt != null
                || resetSession.Otp.VerifiedAt == null)
            {
                resetSession.IsUsed = true;
                resetSession.UsedAt = now;
                await _context.SaveChangesAsync(cancellationToken);

                _logger.LogWarning(
                    "Password reset via verification ticket failed because OTP state was invalid for ResetSessionId {ResetSessionId}, UserId {UserId}",
                    resetSession.ResetSessionID,
                    resetSession.UserID);

                return CreateFailedPasswordResetResult("Verification ticket không hợp lệ hoặc đã hết hạn.");
            }

            resetSession.User.PasswordHash = PasswordHelper.HashPassword(newPassword);
            resetSession.User.UpdatedDate = now;

            resetSession.IsUsed = true;
            resetSession.UsedAt = now;

            resetSession.Otp.IsUsed = true;
            resetSession.Otp.UsedAt = now;

            var otherActiveSessions = await _context.PasswordResetSessions
                .Where(session => session.UserID == resetSession.UserID
                    && !session.IsUsed
                    && session.ResetSessionID != resetSession.ResetSessionID)
                .ToListAsync(cancellationToken);

            foreach (var session in otherActiveSessions)
            {
                session.IsUsed = true;
                session.UsedAt = now;
            }

            var otherActiveOtps = await _context.PasswordResetOtps
                .Where(otp => otp.UserID == resetSession.UserID
                    && otp.Purpose == resetSession.Otp.Purpose
                    && !otp.IsUsed
                    && otp.OtpID != resetSession.OtpID)
                .ToListAsync(cancellationToken);

            foreach (var otp in otherActiveOtps)
            {
                otp.IsUsed = true;
                otp.RevokedAt = now;
            }

            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Password reset completed successfully for UserId {UserId} using ResetSessionId {ResetSessionId} and OtpId {OtpId}",
                resetSession.UserID,
                resetSession.ResetSessionID,
                resetSession.OtpID);

            return new PasswordResetWithVerificationTicketResult
            {
                Success = true,
                Message = "Đặt lại mật khẩu thành công."
            };
        }

        private async Task<int> RevokeActiveOtpsInternalAsync(
            int userId,
            string purpose,
            DateTime now,
            CancellationToken cancellationToken)
        {
            var activeOtps = await _context.PasswordResetOtps
                .Where(otp => otp.UserID == userId
                    && otp.Purpose == purpose
                    && !otp.IsUsed
                    && otp.RevokedAt == null
                    && otp.ExpiresAt > now)
                .ToListAsync(cancellationToken);

            if (activeOtps.Count == 0)
            {
                return 0;
            }

            foreach (var otp in activeOtps)
            {
                otp.IsUsed = true;
                otp.RevokedAt = now;
            }

            await _context.SaveChangesAsync(cancellationToken);
            return activeOtps.Count;
        }

        private static string GenerateOtpCode()
        {
            return RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        }

        private static string NormalizePurpose(string purpose)
        {
            var normalizedPurpose = (purpose ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(normalizedPurpose))
            {
                throw new InvalidOperationException("Purpose là bắt buộc");
            }

            if (normalizedPurpose.Length > 50)
            {
                throw new InvalidOperationException("Purpose không được vượt quá 50 ký tự");
            }

            return normalizedPurpose;
        }

        private static string NormalizeOtpCode(string otpCode)
        {
            var normalizedOtpCode = (otpCode ?? string.Empty).Trim();
            if (normalizedOtpCode.Length != 6 || !normalizedOtpCode.All(char.IsDigit))
            {
                throw new InvalidOperationException("OTP phải gồm đúng 6 chữ số");
            }

            return normalizedOtpCode;
        }

        private static string NormalizeAccount(string account)
        {
            return (account ?? string.Empty).Trim();
        }

        private static string NormalizeVerificationTicket(string verificationTicket)
        {
            var normalizedVerificationTicket = (verificationTicket ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(normalizedVerificationTicket))
            {
                throw new InvalidOperationException("Verification ticket là bắt buộc");
            }

            if (normalizedVerificationTicket.Length < 10 || normalizedVerificationTicket.Length > 300)
            {
                throw new InvalidOperationException("Verification ticket không hợp lệ");
            }

            return normalizedVerificationTicket;
        }

        private static string? NormalizeRequestIp(string? requestIp)
        {
            var normalizedRequestIp = requestIp?.Trim();
            if (string.IsNullOrWhiteSpace(normalizedRequestIp))
            {
                return null;
            }

            return normalizedRequestIp.Length <= 64
                ? normalizedRequestIp
                : normalizedRequestIp[..64];
        }

        private static string? NormalizeRequestUserAgent(string? requestUserAgent)
        {
            var normalizedRequestUserAgent = requestUserAgent?.Trim();
            if (string.IsNullOrWhiteSpace(normalizedRequestUserAgent))
            {
                return null;
            }

            return normalizedRequestUserAgent.Length <= 512
                ? normalizedRequestUserAgent
                : normalizedRequestUserAgent[..512];
        }

        private static PasswordResetOtpVerifyResult CreateFailedVerifyResult(string message)
        {
            return new PasswordResetOtpVerifyResult
            {
                Success = false,
                Message = message
            };
        }

        private static PasswordResetSessionIssueResult CreateFailedSessionIssueResult(string message)
        {
            return new PasswordResetSessionIssueResult
            {
                Success = false,
                Message = message
            };
        }

        private static PasswordResetWithVerificationTicketResult CreateFailedPasswordResetResult(string message)
        {
            return new PasswordResetWithVerificationTicketResult
            {
                Success = false,
                Message = message
            };
        }
    }
}

