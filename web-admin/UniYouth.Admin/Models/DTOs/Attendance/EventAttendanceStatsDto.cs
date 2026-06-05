namespace UniYouth.Admin.Models.DTOs.Attendance
{
    /// <summary>
    /// DTO đại diện cho thống kê điểm danh sự kiện
    /// </summary>
    public class EventAttendanceStatsDto
    {
        public int EventID { get; set; }
        public string? EventName { get; set; }
        public DateTime StartTime { get; set; }
        public int? MaxParticipants { get; set; }

        /// <summary>
        /// Tổng số người đăng ký
        /// </summary>
        public int TotalRegistrations { get; set; }

        /// <summary>
        /// Số điểm danh hợp lệ
        /// </summary>
        public int ValidAttendances { get; set; }

        /// <summary>
        /// Số điểm danh không hợp lệ
        /// </summary>
        public int InvalidAttendances { get; set; }

        /// <summary>
        /// Tỷ lệ điểm danh (%)
        /// </summary>
        public double AttendanceRate { get; set; }

        /// <summary>
        /// Tổng số lần check-in (bao gồm cả valid và invalid)
        /// </summary>
        public int TotalCheckIns => ValidAttendances + InvalidAttendances;

        /// <summary>
        /// Số người chưa check-in
        /// </summary>
        public int NotCheckedIn => TotalRegistrations - TotalCheckIns;
    }
}
