using System.ComponentModel.DataAnnotations;
using UniYouth.Admin.Models.DTOs.AdminUsers;
using UniYouth.Admin.Models.DTOs.Positions;

namespace UniYouth.Admin.Models.ViewModels.Users
{
    public class UserManagementViewModel
    {
        public AdminUserListItemDtoPaginatedResultDto? UsersPage { get; set; }
        public string? Search { get; set; }
        public int? Status { get; set; }
        public string? Role { get; set; }

        public CreateUserViewModel CreateUser { get; set; } = new();
        public UpdateUserRolesViewModel UpdateRoles { get; set; } = new();
        public UpdateUserStatusViewModel UpdateStatus { get; set; } = new();
        public IReadOnlyList<PositionOptionDto> PositionOptions { get; set; } = Array.Empty<PositionOptionDto>();
    }

    public class CreateUserViewModel
    {
        [Required]
        [StringLength(20, MinimumLength = 6, ErrorMessage = "Mã phải từ 6 đến 20 ký tự.")]
        public string Code { get; set; } = string.Empty;

        [Required]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Họ tên phải từ 2 đến 100 ký tự.")]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [StringLength(100, MinimumLength = 5, ErrorMessage = "Email phải từ 5 đến 100 ký tự.")]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [StringLength(20, MinimumLength = 10, ErrorMessage = "Số điện thoại phải từ 10 đến 20 ký tự.")]
        public string? Phone { get; set; }

        public bool? Gender { get; set; }

        [DataType(DataType.Date)]
        public DateTime? DateOfBirth { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Vui lòng chọn chức vụ.")]
        [Display(Name = "Chức vụ")]
        public int? PositionId { get; set; }

        [Required]
        [Display(Name = "Roles (CSV)")]
        public string RolesCsv { get; set; } = "Admin";
    }

    public class UpdateUserRolesViewModel
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Người dùng không hợp lệ.")]
        public int UserId { get; set; }

        [Required]
        [Display(Name = "Roles (CSV)")]
        public string RolesCsv { get; set; } = "CanBo";
    }

    public class UpdateUserStatusViewModel
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Người dùng không hợp lệ.")]
        public int UserId { get; set; }

        [Range(0, 1)]
        public int Status { get; set; } = 1;
    }
}
