namespace UniYouth.Admin.Models.DTOs.Stats
{
    /// <summary>
    /// DTO cho item trong danh sách thống kê tất cả events
    /// Khớp với EventStatsListItemDto từ Swagger
    /// </summary>
    public class EventStatsListItem
    {
        public int EventID { get; set; }
        public string? EventName { get; set; }
        public DateTime StartTime { get; set; }
        public string? Status { get; set; }
        public int? MaxParticipants { get; set; }
        public int TotalRegistrations { get; set; }
        public int ValidAttendances { get; set; }
        public int InvalidAttendances { get; set; }
        public double AttendanceRate { get; set; }
        public int NotCheckedIn { get; set; }
    }
}
