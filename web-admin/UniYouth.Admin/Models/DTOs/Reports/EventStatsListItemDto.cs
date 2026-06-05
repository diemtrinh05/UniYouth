namespace UniYouth.Admin.Models.DTOs.Reports
{
    /// <summary>
    /// DTO cho một item trong danh sách thống kê sự kiện
    /// Map trực tiếp với EventStatsListItemDto từ API
    /// 
    /// API Endpoint: GET /api/events/all/attendance-stats
    /// Database source: vw_EventAttendanceStats
    /// </summary>
    public class EventStatsListItemDto
    {
        /// <summary>
        /// ID của sự kiện
        /// </summary>
        public int EventID { get; set; }

        /// <summary>
        /// Tên sự kiện
        /// </summary>
        public string? EventName { get; set; }

        /// <summary>
        /// Thời gian bắt đầu sự kiện
        /// </summary>
        public DateTime StartTime { get; set; }

        /// <summary>
        /// Trạng thái sự kiện (Draft, Open, Ongoing, Closed, Cancelled)
        /// </summary>
        public string? Status { get; set; }

        /// <summary>
        /// Số lượng người tham gia tối đa (null = không giới hạn)
        /// </summary>
        public int? MaxParticipants { get; set; }

        /// <summary>
        /// Tổng số lượt đăng ký
        /// </summary>
        public int TotalRegistrations { get; set; }

        /// <summary>
        /// Số lượt điểm danh hợp lệ (đúng thời gian, đúng địa điểm)
        /// </summary>
        public int ValidAttendances { get; set; }

        /// <summary>
        /// Số lượt điểm danh không hợp lệ (sai thời gian hoặc địa điểm)
        /// </summary>
        public int InvalidAttendances { get; set; }

        /// <summary>
        /// Tỷ lệ tham gia (%)
        /// Công thức: (ValidAttendances / TotalRegistrations) * 100
        /// </summary>
        public double AttendanceRate { get; set; }

        /// <summary>
        /// Số người đăng ký nhưng không check-in
        /// </summary>
        public int NotCheckedIn { get; set; }
    }
}
