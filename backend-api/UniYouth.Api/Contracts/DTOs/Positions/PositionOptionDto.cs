namespace UniYouth.Api.Contracts.DTOs.Positions
{
    public class PositionOptionDto
    {
        public int PositionId { get; set; }
        public string PositionCode { get; set; } = string.Empty;
        public string PositionName { get; set; } = string.Empty;
        public int UnitId { get; set; }
        public string UnitName { get; set; } = string.Empty;
        public int InstituteId { get; set; }
        public string? InstituteName { get; set; }
        public byte? IsActive { get; set; }
        public int SortOrder { get; set; }
    }
}
