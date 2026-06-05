namespace UniYouth.Api.Contracts.DTOs.Reports
{
    /// <summary>
    /// DTO thống kê tổng hợp tình hình điểm danh của một sự kiện
    /// 
    /// ĐƯỢC SỬ DỤNG CHO:
    /// - Web admin dashboard
    /// - Báo cáo hiệu quả tổ chức sự kiện
    /// - Theo dõi tỷ lệ tham gia thực tế
    /// 
    /// Dữ liệu thường được lấy từ database view (vw_EventAttendanceStats)
    /// để đảm bảo hiệu năng và tính nhất quán.
    /// </summary>
    public class EventAttendanceStatsDto
    {
        /// <summary>
        /// ID sự kiện
        /// </summary>
        public int EventID { get; set; }

        /// <summary>
        /// Tên sự kiện
        /// </summary>
        public string EventName { get; set; } = string.Empty;

        /// <summary>
        /// Thời gian bắt đầu sự kiện
        /// </summary>
        public DateTime StartTime { get; set; }

        /// <summary>
        /// Số lượng người tham gia tối đa
        /// - NULL: không giới hạn số lượng
        /// </summary>
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
        /// Số điểm danh không hợp lệ (GPS ngoài phạm vi, v.v.)
        /// </summary>
        public int InvalidAttendances { get; set; }

        /// <summary>
        /// Tỷ lệ điểm danh (%)
        /// 
        /// Công thức:
        /// = ValidAttendances / TotalRegistrations * 100
        /// </summary>
        public decimal AttendanceRate { get; set; }

        /// <summary>
        /// Tổng số lượt đã thực hiện điểm danh
        /// (bao gồm cả hợp lệ và không hợp lệ)
        /// </summary>
        public int TotalCheckIns => ValidAttendances + InvalidAttendances;

        /// <summary>
        /// Số người đã đăng ký nhưng chưa thực hiện điểm danh
        /// </summary>
        public int NotCheckedIn => TotalRegistrations - TotalCheckIns;
    }
}
