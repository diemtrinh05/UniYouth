using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.Auth
{
    public class ResetPasswordViewModel
    {
        [MinLength(10, ErrorMessage = "Token không hợp lệ")]
        [MaxLength(300, ErrorMessage = "Token không hợp lệ")]
        public string? Token { get; set; }

        public string? VerificationTicket { get; set; }

        public bool IsLegacyTokenFlow { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập mật khẩu mới")]
        [MinLength(8, ErrorMessage = "Mật khẩu mới tối thiểu 8 ký tự")]
        [MaxLength(100, ErrorMessage = "Mật khẩu mới tối đa 100 ký tự")]
        [DataType(DataType.Password)]
        [Display(Name = "Mật khẩu mới")]
        public string NewPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập lại mật khẩu mới")]
        [DataType(DataType.Password)]
        [Display(Name = "Nhập lại mật khẩu mới")]
        [Compare(nameof(NewPassword), ErrorMessage = "Mật khẩu xác nhận không khớp")]
        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
