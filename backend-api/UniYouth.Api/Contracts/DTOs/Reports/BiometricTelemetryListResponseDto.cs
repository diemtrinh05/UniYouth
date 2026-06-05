using UniYouth.Api.Contracts.DTOs.Common;

namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class BiometricTelemetryListResponseDto
    {
        public PaginatedResultDto<BiometricTelemetryItemDto> Telemetry { get; set; } = new();
    }
}
