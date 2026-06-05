using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.Auth
{
    public class ForgotPasswordViewModel
    {
        [Required(ErrorMessage = "Vui lòng nhập tài khoản")]
        [MaxLength(50, ErrorMessage = "Tài khoản tối đa 50 ký tự")]
        [Display(Name = "Tài khoản")]
        public string Account { get; set; } = string.Empty;
    }
}
