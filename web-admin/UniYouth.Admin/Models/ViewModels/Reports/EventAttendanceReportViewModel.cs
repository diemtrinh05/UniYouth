namespace UniYouth.Admin.Models.ViewModels.Reports
{
    /// <summary>
    /// ViewModel cho trang chi tiết báo cáo một sự kiện
    /// Chứa thông tin thống kê chi tiết về điểm danh
    /// 
    /// QUAN TRỌNG:
    /// - Dữ liệu này là READ-ONLY
    /// - Được lấy từ database view vw_EventAttendanceStats
    /// - Không được phép chỉnh sửa thông qua giao diện
    /// </summary>
    public class EventAttendanceReportViewModel
    {
        /// <summary>
        /// ID của sự kiện
        /// </summary>
        public int EventId { get; set; }

        /// <summary>
        /// Tên sự kiện
        /// </summary>
        public string EventName { get; set; } = string.Empty;

        /// <summary>
        /// Thời gian bắt đầu sự kiện
        /// </summary>
        public DateTime StartTime { get; set; }

        /// <summary>
        /// Số lượng người tham gia tối đa (null = không giới hạn)
        /// </summary>
        public int? MaxParticipants { get; set; }

        /// <summary>
        /// Tổng số lượt đăng ký
        /// </summary>
        public int TotalRegistrations { get; set; }

        /// <summary>
        /// Số lượt điểm danh hợp lệ
        /// </summary>
        public int ValidAttendances { get; set; }

        /// <summary>
        /// Số lượt điểm danh không hợp lệ
        /// </summary>
        public int InvalidAttendances { get; set; }

        /// <summary>
        /// Tổng số lượt check-in (Valid + Invalid)
        /// </summary>
        public int TotalCheckIns { get; set; }

        /// <summary>
        /// Số người không check-in
        /// </summary>
        public int NotCheckedIn { get; set; }

        /// <summary>
        /// Tỷ lệ tham gia (%)
        /// </summary>
        public double AttendanceRate { get; set; }

        #region Helper Properties

        /// <summary>
        /// Format thời gian bắt đầu
        /// </summary>
        public string StartTimeFormatted => StartTime.ToString("dd/MM/yyyy HH:mm");

        /// <summary>
        /// Format tỷ lệ tham gia
        /// </summary>
        public string AttendanceRateFormatted => $"{AttendanceRate:F1}%";

        /// <summary>
        /// Hiển thị số người tham gia tối đa
        /// </summary>
        public string MaxParticipantsDisplay => MaxParticipants?.ToString() ?? "Không giới hạn";

        /// <summary>
        /// Tỷ lệ sử dụng slot đăng ký (%)
        /// Chỉ tính khi có giới hạn MaxParticipants
        /// </summary>
        public double? RegistrationUtilization
        {
            get
            {
                if (!MaxParticipants.HasValue || MaxParticipants.Value == 0)
                    return null;
                return (double)TotalRegistrations / MaxParticipants.Value * 100;
            }
        }

        /// <summary>
        /// Format tỷ lệ sử dụng slot đăng ký
        /// </summary>
        public string RegistrationUtilizationFormatted =>
            RegistrationUtilization.HasValue
                ? $"{RegistrationUtilization.Value:F1}%"
                : "N/A";

        /// <summary>
        /// CSS class cho progress bar tỷ lệ tham gia
        /// </summary>
        public string ProgressBarClass
        {
            get
            {
                if (AttendanceRate >= 70) return "bg-success";
                if (AttendanceRate >= 50) return "bg-warning";
                return "bg-danger";
            }
        }

        /// <summary>
        /// Đánh giá mức độ tham gia
        /// </summary>
        public string PerformanceRating
        {
            get
            {
                if (AttendanceRate >= 70) return "Xuất sắc";
                if (AttendanceRate >= 50) return "Tốt";
                return "Cần cải thiện";
            }
        }

        /// <summary>
        /// Icon cho đánh giá mức độ tham gia
        /// </summary>
        public string PerformanceIcon
        {
            get
            {
                if (AttendanceRate >= 70) return "bi-emoji-smile-fill";
                if (AttendanceRate >= 50) return "bi-emoji-neutral-fill";
                return "bi-emoji-frown-fill";
            }
        }

        /// <summary>
        /// CSS class cho text đánh giá
        /// </summary>
        public string PerformanceTextClass
        {
            get
            {
                if (AttendanceRate >= 70) return "text-success";
                if (AttendanceRate >= 50) return "text-warning";
                return "text-danger";
            }
        }

        /// <summary>
        /// Tính % của từng loại so với tổng đăng ký
        /// </summary>
        public double GetPercentage(int count)
        {
            if (TotalRegistrations == 0) return 0;
            return (double)count / TotalRegistrations * 100;
        }

        #endregion
    }
}
