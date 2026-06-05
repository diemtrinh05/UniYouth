using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace UniYouth.Api.Shared.Extensions
{
    public static class ClaimsPrincipalExtensions
    {
        /// <summary>
        /// Lấy UserID từ JWT claims
        /// Ưu tiên theo thứ tự: NameIdentifier → userId → sub
        /// </summary>
        public static int GetUserId(this ClaimsPrincipal user)
        {
            var userIdClaim =
                user.FindFirst(ClaimTypes.NameIdentifier)?.Value ??
                user.FindFirst("userId")?.Value ??
                user.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                throw new UnauthorizedAccessException("Không tìm thấy UserID trong JWT");

            if (!int.TryParse(userIdClaim, out var userId))
                throw new UnauthorizedAccessException("UserID trong JWT không hợp lệ");

            return userId;
        }

        /// <summary>
        /// Lấy UnitID từ JWT claims (nếu có). Trả về null nếu không có hoặc không hợp lệ.
        /// </summary>
        public static int? GetUnitIdOrNull(this ClaimsPrincipal user)
        {
            var value = user.FindFirst("unitId")?.Value;
            return int.TryParse(value, out var unitId) ? unitId : null;
        }

        /// <summary>
        /// Lấy InstituteID từ JWT claims (nếu có). Trả về null nếu không có hoặc không hợp lệ.
        /// </summary>
        public static int? GetInstituteIdOrNull(this ClaimsPrincipal user)
        {
            var value = user.FindFirst("instituteId")?.Value;
            return int.TryParse(value, out var instituteId) ? instituteId : null;
        }
    }
}
