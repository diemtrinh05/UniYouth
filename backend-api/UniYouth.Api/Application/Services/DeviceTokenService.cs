using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.DeviceTokens;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Services
{
    public interface IDeviceTokenService
    {
        Task RegisterAsync(int userId, RegisterDeviceTokenRequestDto dto, CancellationToken cancellationToken);
        Task UnregisterAsync(int userId, UnregisterDeviceTokenRequestDto dto, CancellationToken cancellationToken);
        Task<List<UserDeviceToken>> GetActiveTokensAsync(int userId, CancellationToken cancellationToken);
        Task MarkTokenAsInvalidAsync(int userDeviceTokenId, string? reason, CancellationToken cancellationToken);
    }

    public sealed class DeviceTokenService : IDeviceTokenService
    {
        private readonly UniYouthDbContext _context;
        private readonly ILogger<DeviceTokenService> _logger;

        public DeviceTokenService(UniYouthDbContext context, ILogger<DeviceTokenService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task RegisterAsync(int userId, RegisterDeviceTokenRequestDto dto, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(dto.Token))
            {
                throw new InvalidOperationException("Device token không hợp lệ");
            }

            var platform = dto.Platform.ToString();
            var now = DateTime.Now;

            var existingByToken = await _context.UserDeviceTokens
                .FirstOrDefaultAsync(
                    t => t.Platform == platform && t.Token == dto.Token,
                    cancellationToken);

            if (existingByToken == null)
            {
                _context.UserDeviceTokens.Add(new UserDeviceToken
                {
                    UserID = userId,
                    Platform = platform,
                    Token = dto.Token,
                    DeviceId = dto.DeviceId,
                    IsActive = true,
                    LastSeenAt = now,
                    CreatedDate = now,
                    UpdatedDate = now
                });

                await _context.SaveChangesAsync(cancellationToken);
                return;
            }

            // Token có thể chuyển user (đăng xuất tài khoản A, đăng nhập tài khoản B trên cùng thiết bị).
            existingByToken.UserID = userId;
            existingByToken.DeviceId = dto.DeviceId ?? existingByToken.DeviceId;
            existingByToken.IsActive = true;
            existingByToken.LastSeenAt = now;
            existingByToken.UpdatedDate = now;

            await _context.SaveChangesAsync(cancellationToken);
        }

        public async Task UnregisterAsync(int userId, UnregisterDeviceTokenRequestDto dto, CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(dto.Token))
            {
                throw new InvalidOperationException("Device token không hợp lệ");
            }

            var platform = dto.Platform.ToString();
            var now = DateTime.Now;

            var token = await _context.UserDeviceTokens
                .FirstOrDefaultAsync(
                    t => t.UserID == userId && t.Platform == platform && t.Token == dto.Token,
                    cancellationToken);

            if (token == null)
            {
                return;
            }

            token.IsActive = false;
            token.UpdatedDate = now;
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Đã hủy device token cho UserId={UserId}, Platform={Platform}", userId, platform);
        }

        public Task<List<UserDeviceToken>> GetActiveTokensAsync(int userId, CancellationToken cancellationToken)
        {
            return _context.UserDeviceTokens
                .Where(t => t.UserID == userId && t.IsActive)
                .OrderByDescending(t => t.LastSeenAt)
                .ToListAsync(cancellationToken);
        }

        public async Task MarkTokenAsInvalidAsync(int userDeviceTokenId, string? reason, CancellationToken cancellationToken)
        {
            var token = await _context.UserDeviceTokens
                .FirstOrDefaultAsync(t => t.UserDeviceTokenID == userDeviceTokenId, cancellationToken);

            if (token == null || !token.IsActive)
            {
                return;
            }

            token.IsActive = false;
            token.UpdatedDate = DateTime.Now;
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Đã vô hiệu hóa device token không hợp lệ. UserDeviceTokenId={UserDeviceTokenId}, UserId={UserId}, Platform={Platform}, Reason={Reason}",
                token.UserDeviceTokenID,
                token.UserID,
                token.Platform,
                reason);
        }
    }
}
