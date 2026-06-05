using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Users
{
    public class UpdateUserRolesRequestDto
    {
        [Required(ErrorMessage = "Roles là bắt buộc")]
        [MinLength(1, ErrorMessage = "Cần ít nhất 1 role")]
        public List<string> Roles { get; set; } = new();
    }
}

