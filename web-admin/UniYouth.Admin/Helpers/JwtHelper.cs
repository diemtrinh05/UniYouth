using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace UniYouth.Admin.Helpers
{
    /// <summary>
    /// Helper class để validate và đọc JWT token
    /// Xử lý tất cả logic liên quan đến JWT
    /// </summary>
    public class JwtHelper
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<JwtHelper> _logger;

        public JwtHelper(IConfiguration configuration, ILogger<JwtHelper> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Validate JWT token và extract claims
        /// </summary>
        /// <param name="token">JWT token string</param>
        /// <returns>ClaimsPrincipal nếu token hợp lệ, null nếu không hợp lệ</returns>
        public ClaimsPrincipal? ValidateToken(string token)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();

                // Đọc token để lấy issuer và audience từ token
                // Vì backend API đã sign token, ta cần validate với cùng thông số
                var jwtToken = tokenHandler.ReadJwtToken(token);

                // Lấy secret key từ configuration
                // CHÚ Ý: Secret key này phải GIỐNG với secret key trong API
                // Trong thực tế, nên lưu trong User Secrets hoặc Azure Key Vault
                var secretKey = _configuration["JwtSettings:SecretKey"]
                    ?? throw new InvalidOperationException("JWT SecretKey chưa được cấu hình");

                var validationParameters = new TokenValidationParameters
                {
                    // Validate token signature
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),

                    // Validate issuer (server phát hành token)
                    ValidateIssuer = true,
                    ValidIssuer = _configuration["JwtSettings:Issuer"] ?? jwtToken.Issuer,

                    // Validate audience (app sử dụng token)
                    ValidateAudience = true,
                    ValidAudience = _configuration["JwtSettings:Audience"] ?? jwtToken.Audiences.FirstOrDefault(),

                    // Validate token chưa hết hạn
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero // Không cho phép độ lệch thời gian
                };

                // Validate token và extract claims
                var principal = tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);

                // Kiểm tra token có phải JWT không
                if (validatedToken is not JwtSecurityToken jwtSecurityToken ||
                    !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
                {
                    _logger.LogWarning("Token không phải là JWT hợp lệ");
                    return null;
                }

                _logger.LogDebug("Token validation thành công");
                return principal;
            }
            catch (SecurityTokenExpiredException ex)
            {
                _logger.LogWarning("Token đã hết hạn: {Message}", ex.Message);
                return null;
            }
            catch (SecurityTokenException ex)
            {
                _logger.LogWarning("Token không hợp lệ: {Message}", ex.Message);
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi validate token");
                return null;
            }
        }

        /// <summary>
        /// Extract user info từ ClaimsPrincipal
        /// </summary>
        public UserInfo? ExtractUserInfo(ClaimsPrincipal principal)
        {
            try
            {
                // Lấy các claim cần thiết
                // CHÚ Ý: Claim types phải khớp với những gì API đã set trong token
                var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier)
                    ?? principal.FindFirst("sub")
                    ?? principal.FindFirst("userId");

                var emailClaim = principal.FindFirst(ClaimTypes.Email)
                    ?? principal.FindFirst("email");

                var nameClaim = principal.FindFirst(ClaimTypes.Name)
                    ?? principal.FindFirst("name")
                    ?? principal.FindFirst("fullName");

                var roleValues = principal.Claims
                    .Where(c =>
                        string.Equals(c.Type, ClaimTypes.Role, StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(c.Type, "role", StringComparison.OrdinalIgnoreCase))
                    .SelectMany(c => SplitRoleClaimValue(c.Value))
                    .Where(v => !string.IsNullOrWhiteSpace(v))
                    .Select(v => v.Trim())
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToList();

                var codeClaim = principal.FindFirst("code");

                var instituteIdClaim = principal.Claims.FirstOrDefault(c =>
                    string.Equals(c.Type, "instituteId", StringComparison.OrdinalIgnoreCase));

                var unitIdClaim = principal.Claims.FirstOrDefault(c =>
                    string.Equals(c.Type, "unitId", StringComparison.OrdinalIgnoreCase));

                if (userIdClaim == null || roleValues.Count == 0)
                {
                    _logger.LogWarning("Token thiếu claims bắt buộc (userId hoặc role)");
                    return null;
                }

                return new UserInfo
                {
                    UserId = int.Parse(userIdClaim.Value),
                    Email = emailClaim?.Value ?? string.Empty,
                    FullName = nameClaim?.Value ?? string.Empty,
                    Roles = roleValues,
                    Code = codeClaim?.Value ?? string.Empty,
                    InstituteId = TryParseIntOrNull(instituteIdClaim?.Value),
                    UnitId = TryParseIntOrNull(unitIdClaim?.Value)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi extract user info từ claims");
                return null;
            }
        }

        private static int? TryParseIntOrNull(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return null;
            }

            return int.TryParse(value, out var parsed) ? parsed : null;
        }

        private static IEnumerable<string> SplitRoleClaimValue(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                yield break;
            }

            // Some JWTs may emit a single role claim with comma-separated values.
            // Backend documents "role can be many roles" but not the exact encoding,
            // so we support both "many claims" and "one claim with commas".
            if (value.Contains(','))
            {
                foreach (var part in value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
                {
                    yield return part;
                }

                yield break;
            }

            yield return value;
        }
    }

    /// <summary>
    /// Thông tin user được extract từ JWT token
    /// </summary>
    public class UserInfo
    {
        public int UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public List<string> Roles { get; set; } = new();
        public string Code { get; set; } = string.Empty;

        public int? InstituteId { get; set; }
        public int? UnitId { get; set; }

        public string RolesDisplay => Roles.Count == 0 ? string.Empty : string.Join(", ", Roles);

        /// <summary>
        /// Kiểm tra user có phải Admin không
        /// </summary>
        public bool IsAdmin => Roles.Any(r => r.Equals("Admin", StringComparison.OrdinalIgnoreCase));

        /// <summary>
        /// Kiểm tra user có phải CanBo không
        /// </summary>
        public bool IsCanBo => Roles.Any(r => r.Equals("CanBo", StringComparison.OrdinalIgnoreCase));

        /// <summary>
        /// Kiểm tra user có quyền truy cập Admin web không
        /// </summary>
        public bool HasAdminAccess => IsAdmin || IsCanBo;
    }
}


