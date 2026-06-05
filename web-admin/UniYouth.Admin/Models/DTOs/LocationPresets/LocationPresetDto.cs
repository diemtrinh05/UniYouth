namespace UniYouth.Admin.Models.DTOs.LocationPresets
{
    public class LocationPresetDto
    {
        public int LocationPresetId { get; set; }
        public string? Name { get; set; }
        public string? Address { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public int? RadiusMeters { get; set; }
        public int? InstituteId { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime UpdatedDate { get; set; }
    }
}
