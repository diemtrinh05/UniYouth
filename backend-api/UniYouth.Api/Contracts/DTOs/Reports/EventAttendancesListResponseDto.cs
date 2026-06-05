using UniYouth.Api.Contracts.DTOs.Common;

namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class EventAttendancesListResponseDto
    {
        public int EventId { get; set; }
        public EventAttendancesSummaryDto Summary { get; set; } = new();
        public PaginatedResultDto<AttendanceDetailDto> Attendances { get; set; } = new();
    }
}
