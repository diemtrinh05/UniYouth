using System.ComponentModel.DataAnnotations;
using UniYouth.Admin.Models.DTOs.Positions;

namespace UniYouth.Admin.Models.ViewModels.Users
{
    public class UpdateAdminUserProfileViewModel
    {
        [Required]
        public int UserId { get; set; }

        public string? Code { get; set; }

        [Required]
        [MinLength(2)]
        [MaxLength(100)]
        [Display(Name = "Họ tên")]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(100)]
        [Display(Name = "Email")]
        public string Email { get; set; } = string.Empty;

        [MaxLength(20)]
        [Display(Name = "SĐT")]
        public string? Phone { get; set; }

        [Display(Name = "Giới tính")]
        public bool? Gender { get; set; }

        [DataType(DataType.Date)]
        [Display(Name = "Ngày sinh")]
        public DateTime? DateOfBirth { get; set; }

        [MaxLength(255)]
        [Display(Name = "Địa chỉ")]
        public string? Address { get; set; }

        [Display(Name = "Đơn vị")]
        public string? UnitName { get; set; }

        [Display(Name = "Chức vụ")]
        public int? PositionId { get; set; }

        [DataType(DataType.Date)]
        [Display(Name = "Ngày tham gia")]
        public DateTime? JoinDate { get; set; }

        public string? ReturnUrl { get; set; }
        public IReadOnlyList<PositionOptionDto> PositionOptions { get; set; } = Array.Empty<PositionOptionDto>();
    }
}
