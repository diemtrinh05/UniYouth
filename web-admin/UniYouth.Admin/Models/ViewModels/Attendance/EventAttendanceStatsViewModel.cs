namespace UniYouth.Admin.Models.ViewModels.Attendance
{
    /// <summary>
    /// ViewModel cho thống kê điểm danh
    /// </summary>
    public class EventAttendanceStatsViewModel
    {
        public int EventID { get; set; }
        public string EventName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public int? MaxParticipants { get; set; }
        public int TotalRegistrations { get; set; }
        public int ValidAttendances { get; set; }
        public int InvalidAttendances { get; set; }
        public double AttendanceRate { get; set; }
        public int TotalCheckIns { get; set; }
        public int NotCheckedIn { get; set; }

        /// <summary>
        /// Helper: Tỷ lệ điểm danh hợp lệ so với đăng ký (%)
        /// </summary>
        public double ValidAttendanceRate => TotalRegistrations > 0
            ? (ValidAttendances * 100.0 / TotalRegistrations)
            : 0;
    }
}
