using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Users
{
    public class CreateUserRequestDto
    {
        [Required(ErrorMessage = "Code là bắt buộc")]
        [StringLength(20, MinimumLength = 6, ErrorMessage = "Code phải từ 6 đến 20 ký tự")]
        public string Code { get; set; } = string.Empty;

        [Required(ErrorMessage = "FullName là bắt buộc")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "FullName phải từ 2 đến 100 ký tự")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email là bắt buộc")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        [StringLength(100, MinimumLength = 5, ErrorMessage = "Email phải từ 5 đến 100 ký tự")]
        public string Email { get; set; } = string.Empty;

        [StringLength(20, MinimumLength = 10, ErrorMessage = "Phone phải từ 10 đến 20 ký tự")]
        public string? Phone { get; set; }

        public bool? Gender { get; set; }

        public DateOnly? DateOfBirth { get; set; }

        [Required(ErrorMessage = "PositionId là bắt buộc")]
        [Range(1, int.MaxValue, ErrorMessage = "PositionId không hợp lệ")]
        public int PositionId { get; set; }

        public DateOnly? JoinDate { get; set; }

        [Required(ErrorMessage = "Roles là bắt buộc")]
        [MinLength(1, ErrorMessage = "Cần ít nhất 1 role")]
        public List<string> Roles { get; set; } = new();
    }
}

