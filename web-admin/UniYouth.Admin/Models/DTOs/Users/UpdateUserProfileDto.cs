using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.DTOs.Users
{
    public class UpdateUserProfileDto
    {
        [Required]
        [MinLength(2)]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [MaxLength(20)]
        public string? Phone { get; set; }

        [MaxLength(255)]
        [Url]
        public string? AvatarUrl { get; set; }

        public bool? Gender { get; set; }

        [DataType(DataType.Date)]
        public DateOnly? DateOfBirth { get; set; }

        [MaxLength(255)]
        public string? Address { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "InstituteId phải >= 1")]
        public int? InstituteId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "PositionId phải >= 1")]
        public int? PositionId { get; set; }

        [DataType(DataType.Date)]
        public DateOnly? JoinDate { get; set; }

    }
}
