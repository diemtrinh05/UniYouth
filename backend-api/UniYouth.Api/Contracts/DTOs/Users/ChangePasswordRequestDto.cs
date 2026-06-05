using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Users
{
    /// <summary>
    /// DTO dùng để đổi mật khẩu người dùng
    /// Áp dụng cho người dùng đã đăng nhập muốn đổi mật khẩu của chính mình
    /// </summary>
    public class ChangePasswordRequestDto
    {
        /// <summary>
        /// Mật khẩu hiện tại dùng để xác thực
        /// Bắt buộc nhằm ngăn chặn việc đổi mật khẩu trái phép
        [Required(ErrorMessage = "Mật khẩu hiện tại là bắt buộc")]
        [DataType(DataType.Password)]
        public string CurrentPassword { get; set; } = string.Empty;

        /// <summary>
        /// Mật khẩu mới
        /// Phải đáp ứng yêu cầu bảo mật (tối thiểu 8 ký tự)
        /// </summary>
        [Required(ErrorMessage = "Mật khẩu mới là bắt buộc")]
        [StringLength(100, MinimumLength = 8, ErrorMessage = "Mật khẩu mới phải có ít nhất 8 ký tự")]
        [DataType(DataType.Password)]
        public string NewPassword { get; set; } = string.Empty;

        /// <summary>
        /// Xác nhận mật khẩu mới
        /// Phải trùng với mật khẩu mới để tránh nhập sai
        /// </summary>
        [Required(ErrorMessage = "Xác nhận mật khẩu mới là bắt buộc")]
        [Compare(nameof(NewPassword), ErrorMessage = "Mật khẩu mới và xác nhận mật khẩu không khớp")]
        [DataType(DataType.Password)]
        public string ConfirmNewPassword { get; set; } = string.Empty;
    }
}
