using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using UniYouth.Api.Contracts.DTOs.Auth;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using BC = BCrypt.Net.BCrypt;

namespace UniYouth.Api.Application.Services
{
    public interface IAuthService
    {
        Task<LoginResponseDto?> LoginAsync(
            LoginRequestDto request,
            string? requestIp = null,
            string? requestUserAgent = null);

        Task<LoginResponseDto?> RefreshTokenAsync(
            string refreshToken,
            string? requestIp = null,
            string? requestUserAgent = null);

        Task<bool> RevokeRefreshTokenAsync(
            string refreshToken,
            string? requestIp = null,
            string? requestUserAgent = null,
            string? revokeReason = null);

        Task<int> RevokeAllRefreshTokensForUserAsync(
            int userId,
            string? requestIp = null,
            string? requestUserAgent = null,
            string? revokeReason = null);
    }

    public class AuthService : IAuthService
    {
        private readonly UniYouthDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly IPublicUrlBuilder _publicUrlBuilder;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            UniYouthDbContext context,
            IConfiguration configuration,
            IPublicUrlBuilder publicUrlBuilder,
            ILogger<AuthService> logger)
        {
            _context = context;
            _configuration = configuration;
            _publicUrlBuilder = publicUrlBuilder;
            _logger = logger;
        }

        public async Task<LoginResponseDto?> LoginAsync(
            LoginRequestDto request,
            string? requestIp = null,
            string? requestUserAgent = null)
        {
            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Code == request.Code);

                if (user == null)
                {
                    _logger.LogWarning("Đăng nhập thất bại: Không tìm thấy người dùng với Code {Code}", request.Code);
                    return null;
                }

                var isFirstLoginActivation = user.Status == 0 && user.LastLoginDate == null;
                if (user.Status != 1 && !isFirstLoginActivation)
                {
                    _logger.LogWarning("Đăng nhập thất bại: Tài khoản {Code} đang bị vô hiệu hóa", request.Code);
                    return null;
                }

                if (!BC.Verify(request.Password, user.PasswordHash))
                {
                    _logger.LogWarning("Đăng nhập thất bại: Mật khẩu không đúng cho tài khoản {Code}", request.Code);
                    return null;
                }

                var userRoles = await GetUserRolesAsync(user.UserID);
                if (!userRoles.Any())
                {
                    _logger.LogWarning("Đăng nhập thất bại: Người dùng {Code} chưa được phân quyền", request.Code);
                    return null;
                }

                var userUnit = await GetActiveUserUnitAsync(user.UserID);
                var authSession = CreateLoginResponse(user, userRoles, userUnit);

                _context.RefreshTokens.Add(CreateRefreshTokenRecord(
                    user.UserID,
                    authSession.RefreshToken,
                    authSession.RefreshTokenExpiresAt,
                    requestIp,
                    requestUserAgent));

                if (isFirstLoginActivation)
                {
                    user.Status = 1;
                }

                user.LastLoginDate = DateTime.Now;
                user.UpdatedDate = DateTime.Now;
                await _context.SaveChangesAsync();

                _logger.LogInformation("Người dùng {Code} đăng nhập thành công", request.Code);
                return authSession;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi xảy ra trong quá trình đăng nhập với Code {Code}", request.Code);
                throw;
            }
        }

        public async Task<LoginResponseDto?> RefreshTokenAsync(
            string refreshToken,
            string? requestIp = null,
            string? requestUserAgent = null)
        {
            try
            {
                var normalizedToken = refreshToken?.Trim();
                if (string.IsNullOrWhiteSpace(normalizedToken))
                {
                    return null;
                }

                var storedToken = await _context.RefreshTokens
                    .Include(rt => rt.User)
                    .FirstOrDefaultAsync(rt => rt.TokenHash == HashToken(normalizedToken));

                if (storedToken == null || storedToken.RevokedAt.HasValue || storedToken.ExpiresAt <= DateTime.UtcNow)
                {
                    return null;
                }

                var user = storedToken.User;
                var isFirstLoginActivation = user.Status == 0 && user.LastLoginDate == null;
                if (user.Status != 1 && !isFirstLoginActivation)
                {
                    RevokeRefreshTokenRecord(storedToken, requestIp, requestUserAgent, "user_disabled");
                    await _context.SaveChangesAsync();
                    return null;
                }

                var userRoles = await GetUserRolesAsync(user.UserID);
                if (!userRoles.Any())
                {
                    RevokeRefreshTokenRecord(storedToken, requestIp, requestUserAgent, "roles_missing");
                    await _context.SaveChangesAsync();
                    return null;
                }

                var userUnit = await GetActiveUserUnitAsync(user.UserID);
                var authSession = CreateLoginResponse(user, userRoles, userUnit);

                storedToken.LastUsedAt = DateTime.Now;
                RevokeRefreshTokenRecord(storedToken, requestIp, requestUserAgent, "rotated", authSession.RefreshToken);

                _context.RefreshTokens.Add(CreateRefreshTokenRecord(
                    user.UserID,
                    authSession.RefreshToken,
                    authSession.RefreshTokenExpiresAt,
                    requestIp,
                    requestUserAgent));

                user.UpdatedDate = DateTime.Now;
                await _context.SaveChangesAsync();

                _logger.LogInformation("Refresh token thành công cho UserId {UserId}", user.UserID);
                return authSession;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi refresh token");
                throw;
            }
        }

        public async Task<bool> RevokeRefreshTokenAsync(
            string refreshToken,
            string? requestIp = null,
            string? requestUserAgent = null,
            string? revokeReason = null)
        {
            try
            {
                var normalizedToken = refreshToken?.Trim();
                if (string.IsNullOrWhiteSpace(normalizedToken))
                {
                    return true;
                }

                var storedToken = await _context.RefreshTokens
                    .FirstOrDefaultAsync(rt => rt.TokenHash == HashToken(normalizedToken));

                if (storedToken == null)
                {
                    return true;
                }

                if (!storedToken.RevokedAt.HasValue)
                {
                    RevokeRefreshTokenRecord(
                        storedToken,
                        requestIp,
                        requestUserAgent,
                        string.IsNullOrWhiteSpace(revokeReason) ? "manual_revoke" : revokeReason!);
                    await _context.SaveChangesAsync();
                }

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi revoke refresh token");
                throw;
            }
        }

        public async Task<int> RevokeAllRefreshTokensForUserAsync(
            int userId,
            string? requestIp = null,
            string? requestUserAgent = null,
            string? revokeReason = null)
        {
            var tokens = await _context.RefreshTokens
                .Where(rt => rt.UserID == userId && !rt.RevokedAt.HasValue)
                .ToListAsync();

            foreach (var token in tokens)
            {
                RevokeRefreshTokenRecord(
                    token,
                    requestIp,
                    requestUserAgent,
                    string.IsNullOrWhiteSpace(revokeReason) ? "revoke_all" : revokeReason!);
            }

            if (tokens.Count > 0)
            {
                await _context.SaveChangesAsync();
            }

            return tokens.Count;
        }

        private string GenerateJwtToken(User user, List<string> roles, UserUnit? userUnit)
        {
            var securityKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new("userId", user.UserID.ToString()),
                new(ClaimTypes.NameIdentifier, user.UserID.ToString()),
                new(ClaimTypes.Email, user.Email),
                new("email", user.Email),
                new("fullName", user.FullName),
                new(ClaimTypes.Name, user.FullName),
                new("code", user.Code),
                new(JwtRegisteredClaimNames.Sub, user.UserID.ToString()),
                new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            foreach (var role in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role));
                claims.Add(new Claim("role", role));
            }

            if (userUnit != null)
            {
                claims.Add(new Claim("unitId", userUnit.UnitID.ToString()));
                claims.Add(new Claim("unitName", userUnit.Unit.UnitName));
                claims.Add(new Claim("unitType", userUnit.Unit.UnitType));
                claims.Add(new Claim("instituteId", userUnit.Unit.InstituteID.ToString()));

                if (!string.IsNullOrEmpty(userUnit.Position))
                {
                    claims.Add(new Claim("position", userUnit.Position));
                }
            }

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(_configuration.GetValue<int>("Jwt:ExpireMinutes", 60)),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private LoginResponseDto CreateLoginResponse(User user, List<string> userRoles, UserUnit? userUnit)
        {
            var expiresAt = DateTime.UtcNow.AddMinutes(_configuration.GetValue<int>("Jwt:ExpireMinutes", 60));
            var refreshTokenExpiresAt = DateTime.UtcNow.AddDays(_configuration.GetValue<int>("Jwt:RefreshTokenExpireDays", 30));
            var refreshToken = GenerateSecureToken();

            return new LoginResponseDto
            {
                Token = GenerateJwtToken(user, userRoles, userUnit),
                RefreshToken = refreshToken,
                ExpiresAt = expiresAt,
                RefreshTokenExpiresAt = refreshTokenExpiresAt,
                User = new UserInfoDto
                {
                    UserId = user.UserID,
                    Email = user.Email,
                    FullName = user.FullName,
                    Code = user.Code,
                    AvatarUrl = BuildFullUrl(user.AvatarUrl),
                    Roles = userRoles,
                    Unit = userUnit != null
                        ? new UnitInfoDto
                        {
                            UnitId = userUnit.UnitID,
                            UnitName = userUnit.Unit.UnitName,
                            UnitType = userUnit.Unit.UnitType,
                            Position = userUnit.Position
                        }
                        : null
                }
            };
        }

        private RefreshToken CreateRefreshTokenRecord(
            int userId,
            string plainRefreshToken,
            DateTime refreshTokenExpiresAt,
            string? requestIp,
            string? requestUserAgent)
        {
            return new RefreshToken
            {
                UserID = userId,
                TokenHash = HashToken(plainRefreshToken),
                ExpiresAt = refreshTokenExpiresAt,
                CreatedByIp = NormalizeValue(requestIp, 64),
                CreatedByUserAgent = NormalizeValue(requestUserAgent, 512),
                CreatedDate = DateTime.Now,
                UpdatedDate = DateTime.Now
            };
        }

        private void RevokeRefreshTokenRecord(
            RefreshToken token,
            string? requestIp,
            string? requestUserAgent,
            string revokeReason,
            string? replacementRefreshToken = null)
        {
            if (token.RevokedAt.HasValue)
            {
                return;
            }

            token.RevokedAt = DateTime.Now;
            token.RevokedByIp = NormalizeValue(requestIp, 64);
            token.RevokedByUserAgent = NormalizeValue(requestUserAgent, 512);
            token.RevokedReason = NormalizeValue(revokeReason, 255);
            token.ReplacedByTokenHash = string.IsNullOrWhiteSpace(replacementRefreshToken)
                ? null
                : HashToken(replacementRefreshToken);
            token.UpdatedDate = DateTime.Now;
        }

        private async Task<List<string>> GetUserRolesAsync(int userId)
        {
            return await _context.UserRoles
                .Include(ur => ur.Role)
                .Where(ur => ur.UserID == userId)
                .Select(ur => ur.Role.RoleName)
                .ToListAsync();
        }

        private async Task<UserUnit?> GetActiveUserUnitAsync(int userId)
        {
            return await _context.UserUnits
                .Include(uu => uu.Unit)
                .Where(uu => uu.UserID == userId && uu.Status == 1)
                .OrderByDescending(uu => uu.JoinDate)
                .FirstOrDefaultAsync();
        }

        private static string GenerateSecureToken()
        {
            var bytes = RandomNumberGenerator.GetBytes(64);
            return Convert.ToBase64String(bytes)
                .TrimEnd('=')
                .Replace('+', '-')
                .Replace('/', '_');
        }

        private static string HashToken(string token)
        {
            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(token));
            return Convert.ToHexString(hash);
        }

        private static string? NormalizeValue(string? value, int maxLength)
        {
            var normalized = value?.Trim();
            if (string.IsNullOrWhiteSpace(normalized))
            {
                return null;
            }

            return normalized.Length <= maxLength
                ? normalized
                : normalized[..maxLength];
        }

        private string? BuildFullUrl(string? relativeUrl)
        {
            return _publicUrlBuilder.BuildAbsoluteUrl(relativeUrl);
        }
    }
}

