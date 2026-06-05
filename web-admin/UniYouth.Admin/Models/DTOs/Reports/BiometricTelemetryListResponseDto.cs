namespace UniYouth.Admin.Models.DTOs.Reports
{
    public sealed class BiometricTelemetryListResponseDto
    {
        public BiometricTelemetryPaginatedResultDto Telemetry { get; set; } = new();
    }
}
