namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class AllEventsAttendanceStatsSummaryDto
    {
        public int TotalEvents { get; set; }
        public int TotalRegistrations { get; set; }
        public int TotalValidAttendances { get; set; }
        public int TotalInvalidAttendances { get; set; }
        public decimal AverageAttendanceRate { get; set; }
    }
}

