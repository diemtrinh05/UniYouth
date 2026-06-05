namespace UniYouth.Api.Contracts.DTOs.Notifications
{
    /// <summary>
    /// DTO đại diện cho một thông báo.
    /// Chứa đầy đủ thông tin hiển thị cho người dùng.
    /// </summary>
    public class NotificationDto
    {
        /// <summary>
        /// Mã định danh duy nhất của thông báo
        /// </summary>
        public int NotificationID { get; set; }

        /// <summary>
        /// Tiêu đề thông báo
        /// </summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>
        /// Nội dung chi tiết của thông báo
        /// </summary>
        public string Content { get; set; } = string.Empty;

        /// <summary>
        /// Tên loại thông báo (ví dụ: Đăng ký sự kiện, Điểm danh, Cập nhật sự kiện)
        /// Dùng để frontend phân loại và hiển thị icon phù hợp
        /// </summary>
        public string NotificationType { get; set; } = string.Empty;

        /// <summary>
        /// Mức độ ưu tiên của thông báo
        /// 0: Bình thường
        /// 1: Cao (cần chú ý)
        /// 2: Khẩn cấp
        /// </summary>
        public int? Priority { get; set; }

        /// <summary>
        /// Trạng thái đã đọc hay chưa
        /// </summary>
        public bool? IsRead { get; set; }

        /// <summary>
        /// Thời điểm người dùng đọc thông báo
        /// Null nếu thông báo chưa được đọc
        /// </summary>
        public DateTime? ReadDate { get; set; }

        /// <summary>
        /// Đường dẫn hành động liên quan đến thông báo
        /// Ví dụ: link tới trang chi tiết sự kiện
        /// </summary>
        public string? ActionUrl { get; set; }

        /// <summary>
        /// ID sự kiện liên quan (nếu có)
        /// </summary>
        public int? EventID { get; set; }

        /// <summary>
        /// Tên sự kiện liên quan (để hiển thị)
        /// </summary>
        public string? EventName { get; set; }

        /// <summary>
        /// Thời điểm tạo thông báo
        /// </summary>
        public DateTime? CreatedDate { get; set; }

        /// <summary>
        /// Thời điểm thông báo hết hiệu lực (nếu có)
        /// Sau thời điểm này có thể được xóa bởi background job
        /// </summary>
        public DateTime? ExpiryDate { get; set; }
    }
}
