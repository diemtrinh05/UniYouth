using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Auth
{
    /// <summary>
    /// DTO dùng để nhận dữ liệu đăng nhập của người dùng
    /// </summary>
    public class LoginRequestDto
    {
        /// <summary>
        /// Mã
        /// </summary>
        [Required(ErrorMessage = "Mã là bắt buộc")]
        public string Code { get; set; } = string.Empty;

        /// <summary>
        /// Mật khẩu đăng nhập
        /// </summary>
        [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
        public string Password { get; set; } = string.Empty;
    }
}


