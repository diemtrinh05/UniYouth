namespace UniYouth.Api.Contracts.DTOs.Attendance
{
    /// <summary>
    /// DTO dùng để hiển thị lịch sử điểm danh của người dùng
    /// (danh sách các sự kiện đã check-in)
    /// </summary>
    public class AttendanceHistoryDto
    {
        /// <summary>
        /// ID của bản ghi attendance
        /// </summary>
        public int AttendanceID { get; set; }
        public int EventID { get; set; }
        public string EventName { get; set; } = string.Empty;
        public DateTime? CheckInTime { get; set; }
        public bool? IsValid { get; set; }
        public double? Distance { get; set; }
        public string? InvalidReason { get; set; }
        public bool HasAttendancePointsAwarded { get; set; }
        public int? AttendancePointID { get; set; }
    }
}
