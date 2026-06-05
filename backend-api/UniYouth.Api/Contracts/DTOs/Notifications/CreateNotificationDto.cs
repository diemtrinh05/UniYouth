using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Contracts.DTOs.Notifications
{
    /// <summary>
    /// DTO nội bộ để tạo thông báo mới.
    /// Được sử dụng bởi các service khác để tự động tạo thông báo.
    /// </summary>
    public class CreateNotificationDto
    {
        /// <summary>
        /// ID người dùng nhận thông báo
        /// </summary>
        public int UserID { get; set; }

        /// <summary>
        /// ID sự kiện liên quan (optional)
        /// </summary>
        public int? EventID { get; set; }

        /// <summary>
        /// Tiêu đề thông báo
        /// </summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>
        /// Nội dung thông báo
        /// </summary>
        public string Content { get; set; } = string.Empty;

        /// <summary>
        /// ID loại thông báo
        /// </summary>
        public NotificationTypeEnum NotificationType { get; set; }

        /// <summary>
        /// Mức độ ưu tiên (0: bình thường, 1: cao, 2: khẩn cấp)
        /// </summary>
        public NotificationPriority Priority { get; set; } = NotificationPriority.Normal;

        /// <summary>
        /// Link hành động (optional)
        /// </summary>
        public string? ActionUrl { get; set; }

        /// <summary>
        /// Thời điểm hết hạn (optional)
        /// </summary>
        public DateTime? ExpiryDate { get; set; }

        /// <summary>
        /// Khóa chống tạo trùng notification khi retry/race (internal)
        /// </summary>
        public string? DedupKey { get; set; }

        /// <summary>
        /// Audience metadata để route channel theo actor.
        /// </summary>
        public NotificationAudience? Audience { get; set; }

        /// <summary>
        /// Role target cụ thể của người nhận (DoanVien/HoiVien/CanBo/Admin).
        /// </summary>
        public string? TargetRole { get; set; }
    }
}
