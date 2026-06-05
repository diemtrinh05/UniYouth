namespace UniYouth.Admin.Models.ViewModels.Reports
{
    /// <summary>
    /// ViewModel cho một item trong danh sách báo cáo
    /// Chứa thông tin thống kê điểm danh của một sự kiện
    /// </summary>
    public class EventReportListItemViewModel
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
        /// Trạng thái sự kiện
        /// </summary>
        public string Status { get; set; } = string.Empty;

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
        /// Tỷ lệ tham gia (%)
        /// </summary>
        public double AttendanceRate { get; set; }

        /// <summary>
        /// Số người không check-in
        /// </summary>
        public int NotCheckedIn { get; set; }

        #region Helper Properties cho View

        /// <summary>
        /// Format thời gian bắt đầu: dd/MM/yyyy HH:mm
        /// </summary>
        public string StartTimeFormatted => StartTime.ToString("dd/MM/yyyy HH:mm");

        /// <summary>
        /// Format tỷ lệ tham gia: 85.5%
        /// </summary>
        public string AttendanceRateFormatted => $"{AttendanceRate:F1}%";

        /// <summary>
        /// Hiển thị số người tham gia tối đa hoặc "Không giới hạn"
        /// </summary>
        public string MaxParticipantsDisplay => MaxParticipants?.ToString() ?? "Không giới hạn";

        /// <summary>
        /// CSS class cho badge tỷ lệ tham gia
        /// - Xanh lá (>=70%): Tốt
        /// - Vàng (>=50%): Trung bình
        /// - Đỏ (<50%): Cần cải thiện
        /// </summary>
        public string AttendanceRateBadgeClass
        {
            get
            {
                if (AttendanceRate >= 70) return "badge bg-success";
                if (AttendanceRate >= 50) return "badge bg-warning";
                return "badge bg-danger";
            }
        }

        /// <summary>
        /// CSS class cho badge trạng thái
        /// </summary>
        public string StatusBadgeClass
        {
            get
            {
                return Status?.ToLower() switch
                {
                    "completed" => "badge bg-success",
                    "published" => "badge bg-primary",
                    "cancelled" => "badge bg-danger",
                    "draft" => "badge bg-secondary",
                    _ => "badge bg-secondary"
                };
            }
        }

        /// <summary>
        /// Hiển thị trạng thái bằng tiếng Việt
        /// </summary>
        public string StatusDisplay
        {
            get
            {
                return Status?.ToLower() switch
                {
                    "completed" => "Đã hoàn thành",
                    "published" => "Đang diễn ra",
                    "cancelled" => "Đã hủy",
                    "draft" => "Nháp",
                    _ => Status ?? "Không xác định"
                };
            }
        }

        #endregion
    }
}
