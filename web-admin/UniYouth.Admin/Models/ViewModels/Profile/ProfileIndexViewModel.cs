using System.ComponentModel.DataAnnotations;
using UniYouth.Admin.Models.DTOs.Positions;
using UniYouth.Admin.Models.DTOs.Users;

namespace UniYouth.Admin.Models.ViewModels.Profile
{
    public class ProfileIndexViewModel
    {
        public UserProfileDto? Profile { get; set; }
        public UpdateProfileForm Update { get; set; } = new();
        public ChangePasswordForm ChangePassword { get; set; } = new();
        public IReadOnlyList<PositionOptionDto> PositionOptions { get; set; } = Array.Empty<PositionOptionDto>();
    }

    public class UpdateProfileForm
    {
        [Required]
        [MinLength(2)]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [MaxLength(20)]
        public string? Phone { get; set; }

        public bool? Gender { get; set; }

        [DataType(DataType.Date)]
        public DateTime? DateOfBirth { get; set; }

        [MaxLength(255)]
        public string? Address { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "InstituteId phải >= 1")]
        public int? InstituteId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "PositionId phải >= 1")]
        public int? PositionId { get; set; }

        [DataType(DataType.Date)]
        public DateTime? JoinDate { get; set; }

        public string? UnitName { get; set; }
    }

    public class ChangePasswordForm
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
