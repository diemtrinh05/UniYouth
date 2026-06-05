using UniYouth.Api.Contracts.DTOs.Reports;

namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class AllEventsAttendanceStatsResponseDto
    {
        public AllEventsAttendanceStatsSummaryDto Summary { get; set; } = new();
        public PaginationMetaDto Pagination { get; set; } = new();
        public List<EventStatsListItemDto> Items { get; set; } = new();
    }
}

