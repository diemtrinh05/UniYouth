namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class GetBiometricTelemetryQueryDto
    {
        public int PageNumber { get; set; } = 1;

        public int PageSize { get; set; } = 20;

        public string? Q { get; set; }

        public int? EventId { get; set; }

        public DateTime? From { get; set; }

        public DateTime? To { get; set; }

        public string? FaceStatus { get; set; }

        public string? LivenessStatus { get; set; }

        public bool? OnlyInvalid { get; set; }
    }
}
