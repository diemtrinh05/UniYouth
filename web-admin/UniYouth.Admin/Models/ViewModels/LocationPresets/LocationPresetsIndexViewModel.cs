using System.ComponentModel.DataAnnotations;
using UniYouth.Admin.Models.DTOs.LocationPresets;

namespace UniYouth.Admin.Models.ViewModels.LocationPresets
{
    public class LocationPresetsIndexViewModel
    {
        public LocationPresetDtoPaginatedResultDto? Page { get; set; }

        public string? Q { get; set; }
        public bool IncludeInactive { get; set; }

        public int PageNumber => Page?.PageNumber > 0 ? Page.PageNumber : 1;
        public int PageSize => Page?.PageSize > 0 ? Page.PageSize : 20;
        public int TotalPages => Page?.TotalPages > 0 ? Page.TotalPages : 1;
        public bool HasPreviousPage => Page?.HasPreviousPage ?? PageNumber > 1;
        public bool HasNextPage => Page?.HasNextPage ?? PageNumber < TotalPages;

        public CreateLocationPresetForm Create { get; set; } = new();
    }

    public class CreateLocationPresetForm
    {
        [Required]
        [MaxLength(200)]
        [Display(Name = "Tên preset")]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500)]
        [Display(Name = "Địa chỉ")]
        public string? Address { get; set; }

        [Range(-90, 90)]
        [Display(Name = "Vĩ độ")]
        public double Latitude { get; set; }

        [Range(-180, 180)]
        [Display(Name = "Kinh độ")]
        public double Longitude { get; set; }

        [Range(1, 10000)]
        [Display(Name = "Bán kính (m)")]
        public int? RadiusMeters { get; set; }

        [Display(Name = "Kích hoạt")]
        public bool IsActive { get; set; } = true;
    }

    public class UpdateLocationPresetForm
    {
        [Required]
        public int LocationPresetId { get; set; }

        [Required]
        [MaxLength(200)]
        [Display(Name = "Tên preset")]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500)]
        [Display(Name = "Địa chỉ")]
        public string? Address { get; set; }

        [Range(-90, 90)]
        [Display(Name = "Vĩ độ")]
        public double Latitude { get; set; }

        [Range(-180, 180)]
        [Display(Name = "Kinh độ")]
        public double Longitude { get; set; }

        [Range(1, 10000)]
        [Display(Name = "Bán kính (m)")]
        public int? RadiusMeters { get; set; }

        [Display(Name = "Kích hoạt")]
        public bool IsActive { get; set; } = true;
    }
}
