using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Auth
{
    public class VerifyResetOtpRequestDto
    {
        [Required(ErrorMessage = "Tài khoản là bắt buộc")]
        [StringLength(50, ErrorMessage = "Tài khoản không được vượt quá 50 ký tự")]
        public string Account { get; set; } = string.Empty;

        [Required(ErrorMessage = "OTP là bắt buộc")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "OTP phải gồm đúng 6 chữ số")]
        public string OtpCode { get; set; } = string.Empty;
    }
}
