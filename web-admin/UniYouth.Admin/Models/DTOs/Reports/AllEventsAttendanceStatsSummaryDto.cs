namespace UniYouth.Admin.Models.DTOs.Reports
{
    public class AllEventsAttendanceStatsSummaryDto
    {
        public int TotalEvents { get; set; }
        public int TotalRegistrations { get; set; }
        public int TotalValidAttendances { get; set; }
        public int TotalInvalidAttendances { get; set; }
        public double AverageAttendanceRate { get; set; }
    }
}

