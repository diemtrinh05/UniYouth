namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class EventAttendancesSummaryDto
    {
        public int TotalRecords { get; set; }
        public int ValidCount { get; set; }
        public int InvalidCount { get; set; }
    }
}

