namespace UniYouth.Admin.Models.DTOs.Attendance
{
    public class AttendanceListResponseDto
    {
        public int EventId { get; set; }
        public int TotalRecords { get; set; }
        public int ValidCount { get; set; }
        public int InvalidCount { get; set; }
        public List<AttendanceDetailDto> Attendances { get; set; } = new();
    }
}
