using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.Auth
{
    /// <summary>
    /// ViewModel cho trang đăng nhập
    /// Chứa thông tin cần thiết để user đăng nhập vào hệ thống Admin
    /// </summary>
    public class LoginViewModel
    {
        /// <summary>
        /// Tài khoản - dùng để đăng nhập
        /// </summary>
        [Required(ErrorMessage = "Vui lòng nhập tài khoản")]
        [Display(Name = "Tài khoản")]
        public string Code { get; set; } = string.Empty;

        /// <summary>
        /// Mật khẩu
        /// </summary>
        [Required(ErrorMessage = "Vui lòng nhập mật khẩu")]
        [DataType(DataType.Password)]
        [Display(Name = "Mật khẩu")]
        public string Password { get; set; } = string.Empty;

        /// <summary>
        /// Có ghi nhớ đăng nhập hay không (optional)
        /// Có thể dùng để extend thời gian cookie
        /// </summary>
        [Display(Name = "Ghi nhớ đăng nhập")]
        public bool RememberMe { get; set; }

        /// <summary>
        /// URL để redirect sau khi đăng nhập thành công
        /// </summary>
        public string? ReturnUrl { get; set; }
    }
}

