using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Events
{
    public class UpdateEventTypeRequestDto
    {
        [Required(ErrorMessage = "TypeName là bắt buộc")]
        [StringLength(200, MinimumLength = 1, ErrorMessage = "TypeName không được vượt quá 200 ký tự")]
        public string TypeName { get; set; } = string.Empty;

        [StringLength(255, ErrorMessage = "Description không được vượt quá 255 ký tự")]
        public string? Description { get; set; }
    }
}

