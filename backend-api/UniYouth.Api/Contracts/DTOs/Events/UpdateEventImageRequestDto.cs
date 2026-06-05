using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Events
{
    public class UpdateEventImageRequestDto
    {
        [StringLength(50, ErrorMessage = "ImageType không được vượt quá 50 ký tự")]
        public string? ImageType { get; set; }

        [StringLength(255, ErrorMessage = "Caption không được vượt quá 255 ký tự")]
        public string? Caption { get; set; }
    }
}

