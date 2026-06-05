namespace UniYouth.Api.Contracts.DTOs.Locations
{
    public class LocationPresetDto
    {
        public int LocationPresetId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Address { get; set; }
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
        public int? RadiusMeters { get; set; }
        public int? InstituteId { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime UpdatedDate { get; set; }
    }
}
