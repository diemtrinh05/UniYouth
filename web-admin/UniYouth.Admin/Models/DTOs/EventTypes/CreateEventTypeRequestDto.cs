using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.DTOs.EventTypes
{
    public class CreateEventTypeRequestDto
    {
        [Required]
        [MinLength(1)]
        [MaxLength(200)]
        public string TypeName { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? Description { get; set; }
    }
}

