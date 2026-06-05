namespace UniYouth.Admin.Models.DTOs.Units
{
    public class UnitOptionDto
    {
        public int UnitId { get; set; }
        public string UnitName { get; set; } = string.Empty;
        public string UnitType { get; set; } = string.Empty;
        public int InstituteId { get; set; }
        public string? InstituteName { get; set; }
        public int? Status { get; set; }
    }
}
