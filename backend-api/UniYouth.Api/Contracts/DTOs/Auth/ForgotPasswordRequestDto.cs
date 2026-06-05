using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Auth
{
    public class ForgotPasswordRequestDto
    {
        [Required(ErrorMessage = "Tài khoản là bắt buộc")]
        [StringLength(50, ErrorMessage = "Tài khoản không được vượt quá 50 ký tự")]
        public string Account { get; set; } = string.Empty;
    }
}
