namespace UniYouth.Api.Contracts.DTOs.Reports
{
    /// <summary>
    /// DTO đại diện cho một dòng thống kê sự kiện
    /// 
    /// ĐƯỢC SỬ DỤNG KHI:
    /// - Hiển thị danh sách tổng hợp nhiều sự kiện trên dashboard admin
    /// - So sánh hiệu quả tổ chức giữa các sự kiện
    /// - Theo dõi nhanh tỷ lệ điểm danh
    /// </summary>
    public class EventStatsListItemDto
    {
        public int EventID { get; set; }
        public string EventName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public string Status { get; set; } = string.Empty; // Draft, Open, Ongoing, Closed, Cancelled
        public int? MaxParticipants { get; set; }
        public int TotalRegistrations { get; set; }
        public int ValidAttendances { get; set; }
        public int InvalidAttendances { get; set; }
        public decimal AttendanceRate { get; set; }
        public int NotCheckedIn { get; set; }
    }
}
