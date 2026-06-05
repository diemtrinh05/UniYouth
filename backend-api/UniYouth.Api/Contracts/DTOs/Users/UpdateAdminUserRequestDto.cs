using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Users
{
    public class UpdateAdminUserRequestDto
    {
        [Required(ErrorMessage = "FullName là bắt buộc")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "FullName phải từ 2 đến 100 ký tự")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email là bắt buộc")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        [StringLength(100, ErrorMessage = "Email không được vượt quá 100 ký tự")]
        public string Email { get; set; } = string.Empty;

        [StringLength(20, ErrorMessage = "Phone không được vượt quá 20 ký tự")]
        public string? Phone { get; set; }

        public bool? Gender { get; set; }

        public DateOnly? DateOfBirth { get; set; }

        [StringLength(255, ErrorMessage = "Address không được vượt quá 255 ký tự")]
        public string? Address { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "PositionId không hợp lệ")]
        public int? PositionId { get; set; }

        public DateOnly? JoinDate { get; set; }
    }
}

