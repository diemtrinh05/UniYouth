namespace UniYouth.Api.Contracts.DTOs.Units
{
    public class UnitOptionDto
    {
        public int UnitId { get; set; }
        public string UnitName { get; set; } = string.Empty;
        public string UnitType { get; set; } = string.Empty;
        public int InstituteId { get; set; }
        public string? InstituteName { get; set; }
        public byte? Status { get; set; }
    }
}
