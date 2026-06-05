namespace UniYouth.Api.Contracts.DTOs.Points
{
    /// <summary>
    /// DTO tổng hợp điểm rèn luyện của người dùng
    /// 
    /// ĐƯỢC SỬ DỤNG CHO:
    /// - Mobile app: màn hình hồ sơ / điểm rèn luyện
    /// - Web app: dashboard cá nhân sinh viên
    /// 
    /// </summary>
    public class UserPointSummaryDto
    {
        /// <summary>
        /// Tổng điểm rèn luyện tích lũy
        /// </summary>
        public int TotalPoints { get; set; }

        /// <summary>
        /// Số sự kiện đã tham gia (có nhận điểm)
        /// </summary>
        public int EventsParticipated { get; set; }

        /// <summary>
        /// Số lần điểm danh hợp lệ
        /// </summary>
        public int ValidAttendances { get; set; }

        /// <summary>
        /// Họ tên người dùng
        /// </summary>
        public string FullName { get; set; } = string.Empty;

        /// <summary>
        /// Mã
        /// </summary>
        public string Code { get; set; } = string.Empty;
    }
}


