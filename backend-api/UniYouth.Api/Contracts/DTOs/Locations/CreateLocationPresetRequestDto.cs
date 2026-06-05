using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Locations
{
    public class CreateLocationPresetRequestDto
    {
        [Required(ErrorMessage = "Name là bắt buộc")]
        [StringLength(200, ErrorMessage = "Name không được vượt quá 200 ký tự")]
        public string Name { get; set; } = string.Empty;

        [StringLength(500, ErrorMessage = "Address không được vượt quá 500 ký tự")]
        public string? Address { get; set; }

        [Range(-90, 90, ErrorMessage = "Latitude không hợp lệ")]
        public decimal Latitude { get; set; }

        [Range(-180, 180, ErrorMessage = "Longitude không hợp lệ")]
        public decimal Longitude { get; set; }

        [Range(1, 10000, ErrorMessage = "RadiusMeters phải trong khoảng 1..10000")]
        public int? RadiusMeters { get; set; }

        public int? InstituteId { get; set; }

        public bool? IsActive { get; set; }
    }
}
