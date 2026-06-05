namespace UniYouth.Admin.Models.DTOs.Attendance
{
    public class EventAttendancesListResponseDto
    {
        public int EventId { get; set; }
        public EventAttendancesSummaryDto? Summary { get; set; }
        public AttendanceDetailDtoPaginatedResultDto? Attendances { get; set; }
    }
}

