namespace UniYouth.Admin.Models.DTOs.Reports
{
    public class AllEventsAttendanceStatsResponseDto
    {
        public AllEventsAttendanceStatsSummaryDto? Summary { get; set; }
        public PaginationMetaDto? Pagination { get; set; }
        public List<EventStatsListItemDto>? Items { get; set; }
    }
}

