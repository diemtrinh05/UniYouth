using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.DTOs.AdminUsers
{
    public class UpdateUserRolesRequestDto
    {
        [Required]
        [MinLength(1)]
        public List<string> Roles { get; set; } = new();
    }
}

