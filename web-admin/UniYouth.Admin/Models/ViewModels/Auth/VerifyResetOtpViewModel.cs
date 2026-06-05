using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.Auth
{
    public class VerifyResetOtpViewModel
    {
        [Required(ErrorMessage = "Thiếu tài khoản đặt lại mật khẩu")]
        [MaxLength(50, ErrorMessage = "Tài khoản tối đa 50 ký tự")]
        [Display(Name = "Tài khoản")]
        public string Account { get; set; } = string.Empty;

        public string AccountDisplay { get; set; } = string.Empty;

        [Required(ErrorMessage = "Vui lòng nhập mã OTP")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "OTP phải gồm đúng 6 chữ số")]
        [Display(Name = "Mã OTP")]
        public string OtpCode { get; set; } = string.Empty;

        public DateTime? OtpExpiresAt { get; set; }

        public DateTime? ResendAvailableAt { get; set; }

        public bool CanResend { get; set; }
    }
}
