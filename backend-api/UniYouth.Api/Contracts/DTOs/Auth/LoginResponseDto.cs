using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Auth
{
    /// <summary>
    /// DTO dùng để trả về kết quả khi đăng nhập thành công
    /// </summary>
    public class LoginResponseDto
    {
        /// <summary>
        /// JWT Access Token dùng để xác thực các request tiếp theo
        /// </summary>
        public string Token { get; set; } = string.Empty;

        /// <summary>
        /// Refresh token dùng để cấp lại access token khi access token hết hạn
        /// </summary>
        public string RefreshToken { get; set; } = string.Empty;

        /// <summary>
        /// Kiểu token (mặc định là "Bearer")
        /// </summary>
        public string TokenType { get; set; } = "Bearer";

        /// <summary>
        /// Thời điểm token hết hạn
        /// </summary>
        public DateTime ExpiresAt { get; set; }

        /// <summary>
        /// Thời điểm refresh token hết hạn
        /// </summary>
        public DateTime RefreshTokenExpiresAt { get; set; }

        /// <summary>
        /// Thông tin người dùng sau khi đăng nhập
        /// </summary>
        public UserInfoDto User { get; set; } = null!;
    }

    /// <summary>
    /// DTO chứa thông tin người dùng trong phản hồi đăng nhập
    /// </summary>
    public class UserInfoDto
    {
        /// <summary>
        /// User ID
        /// </summary>
        public int UserId { get; set; }

        /// <summary>
        /// Email
        /// </summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>
        /// Họ và tên
        /// </summary>
        public string FullName { get; set; } = string.Empty;

        /// <summary>
        /// Mã
        /// </summary>
        public string Code { get; set; } = string.Empty;

        /// <summary>
        /// URL ảnh đại diện
        /// </summary>
        public string? AvatarUrl { get; set; }

        /// <summary>
        /// Danh sách vai trò
        /// </summary>
        public List<string> Roles { get; set; } = new();

        /// <summary>
        /// Thông tin đơn vị (nếu có)
        /// </summary>
        public UnitInfoDto? Unit { get; set; }
    }

    /// <summary>
    /// DTO chứa thông tin đơn vị sinh hoạt của người dùng
    /// </summary>
    public class UnitInfoDto
    {
        /// <summary>
        /// Unit ID
        /// </summary>
        public int UnitId { get; set; }

        /// <summary>
        /// Tên đơn vị
        /// </summary>
        public string UnitName { get; set; } = string.Empty;

        /// <summary>
        /// Loại đơn vị (ChiDoan / ChiHoi)
        /// </summary>
        public string UnitType { get; set; } = string.Empty;

        /// <summary>
        /// Chức vụ trong đơn vị
        /// </summary>
        public string? Position { get; set; }
    }
}


