using UniYouth.Admin.Models.DTOs.Users;

namespace UniYouth.Admin.Models.DTOs.Auth
{
    /// <summary>
    /// DTO cho response từ API sau khi đăng nhập thành công
    /// Chứa JWT token và thông tin user
    /// </summary>
    public class LoginResponseDto
    {
        public string Token { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public string TokenType { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public DateTime RefreshTokenExpiresAt { get; set; }
        public UserInfoDto User { get; set; } = new();
    }
}
