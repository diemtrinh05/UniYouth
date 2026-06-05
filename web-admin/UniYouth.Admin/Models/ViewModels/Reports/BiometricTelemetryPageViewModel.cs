using UniYouth.Admin.Models.DTOs.Reports;

namespace UniYouth.Admin.Models.ViewModels.Reports
{
    public sealed class BiometricTelemetryPageViewModel
    {
        public List<BiometricTelemetryItemDto> Items { get; set; } = new();
        public string? SearchTerm { get; set; }
        public int? EventId { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
        public string? FaceStatus { get; set; }
        public string? LivenessStatus { get; set; }
        public bool OnlyInvalid { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;
        public int TotalCount { get; set; }
        public int TotalPages { get; set; } = 1;

        public bool HasFilters =>
            !string.IsNullOrWhiteSpace(SearchTerm) ||
            EventId.HasValue ||
            From.HasValue ||
            To.HasValue ||
            !string.IsNullOrWhiteSpace(FaceStatus) ||
            !string.IsNullOrWhiteSpace(LivenessStatus) ||
            OnlyInvalid;
    }
}
