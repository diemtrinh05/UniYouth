namespace UniYouth.Admin.Models.DTOs.Points
{
    public class UserPointSummaryDto
    {
        public int TotalPoints { get; set; }
        public int EventsParticipated { get; set; }
        public int ValidAttendances { get; set; }
        public string? FullName { get; set; }
        public string? Code { get; set; }
    }
}


