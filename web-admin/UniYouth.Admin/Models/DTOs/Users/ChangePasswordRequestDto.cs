using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.DTOs.Users
{
    public class ChangePasswordRequestDto
    {
        [Required]
        [MinLength(1)]
        [DataType(DataType.Password)]
        public string CurrentPassword { get; set; } = string.Empty;

        [Required]
        [MinLength(8)]
        [MaxLength(100)]
        [DataType(DataType.Password)]
        public string NewPassword { get; set; } = string.Empty;

        [Required]
        [MinLength(1)]
        [DataType(DataType.Password)]
        [Compare(nameof(NewPassword), ErrorMessage = "Xác nhận mật khẩu mới không khớp.")]
        public string ConfirmNewPassword { get; set; } = string.Empty;
    }
}

