using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.DTOs.AdminUsers
{
    public class CreateUserRequestDto
    {
        [Required]
        [StringLength(20, MinimumLength = 6)]
        public string Code { get; set; } = string.Empty;

        [Required]
        [StringLength(100, MinimumLength = 2)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [StringLength(100, MinimumLength = 5)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [StringLength(20, MinimumLength = 10)]
        public string? Phone { get; set; }

        /// <summary>
        /// Nullable boolean in swagger.
        /// </summary>
        public bool? Gender { get; set; }

        public DateOnly? DateOfBirth { get; set; }

        [Range(1, int.MaxValue)]
        public int PositionId { get; set; }

        [Required]
        [MinLength(1)]
        public List<string> Roles { get; set; } = new();
    }
}

