namespace UniYouth.Admin.Models.DTOs.LocationPresets
{
    public class CreateLocationPresetRequestDto
    {
        public string Name { get; set; } = string.Empty;
        public string? Address { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public int? RadiusMeters { get; set; }
        public int? InstituteId { get; set; }
        public bool? IsActive { get; set; }
    }
}
