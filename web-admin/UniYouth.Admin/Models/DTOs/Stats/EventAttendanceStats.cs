namespace UniYouth.Admin.Models.DTOs.Stats
{
    /// <summary>
    /// DTO cho thống kê điểm danh của event
    /// Khớp với EventAttendanceStatsDto từ Swagger
    /// </summary>
    public class EventAttendanceStats
    {
        public int EventID { get; set; }
        public string? EventName { get; set; }
        public DateTime StartTime { get; set; }
        public int? MaxParticipants { get; set; }
        public int TotalRegistrations { get; set; }
        public int ValidAttendances { get; set; }
        public int InvalidAttendances { get; set; }
        public double AttendanceRate { get; set; }
        public int TotalCheckIns { get; set; }
        public int NotCheckedIn { get; set; }
    }
}
