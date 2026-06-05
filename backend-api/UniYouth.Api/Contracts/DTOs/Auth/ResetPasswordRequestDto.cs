using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Auth
{
    public class ResetPasswordRequestDto
    {
        [StringLength(300, MinimumLength = 10, ErrorMessage = "Token không hợp lệ")]
        public string? Token { get; set; }

        [StringLength(300, MinimumLength = 10, ErrorMessage = "Verification ticket không hợp lệ")]
        public string? VerificationTicket { get; set; }

        [Required(ErrorMessage = "Mật khẩu mới là bắt buộc")]
        [StringLength(100, MinimumLength = 8, ErrorMessage = "Mật khẩu mới phải có ít nhất 8 ký tự")]
        [DataType(DataType.Password)]
        public string NewPassword { get; set; } = string.Empty;
    }
}
