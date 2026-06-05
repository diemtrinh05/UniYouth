namespace UniYouth.Admin.Models.DTOs.Reports
{
    public sealed class BiometricTelemetryPaginatedResultDto
    {
        public List<BiometricTelemetryItemDto> Items { get; set; } = new();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => PageSize <= 0 ? 1 : (int)Math.Ceiling((double)TotalCount / PageSize);
    }
}
