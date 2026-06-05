namespace UniYouth.Admin.Models.DTOs.Registration
{
    /// <summary>
    /// DTO đại diện cho thông tin đăng ký sự kiện từ API
    /// Sử dụng khi lấy danh sách người đăng ký
    /// </summary>
    public class EventRegistrationDto
    {
        /// <summary>
        /// ID đăng ký
        /// </summary>
        public int RegistrationID { get; set; }

        /// <summary>
        /// ID sự kiện
        /// </summary>
        public int EventID { get; set; }

        /// <summary>
        /// Tên sự kiện
        /// </summary>
        public string? EventName { get; set; }

        /// <summary>
        /// ID người dùng
        /// </summary>
        public int UserID { get; set; }

        /// <summary>
        /// Họ tên đầy đủ
        /// </summary>
        public string? UserFullName { get; set; }

        /// <summary>
        /// Mã
        /// </summary>
        public string? Code { get; set; }

        /// <summary>
        /// Email
        /// </summary>
        public string? Email { get; set; }

        /// <summary>
        /// Thời gian đăng ký
        /// </summary>
        public DateTime? RegisterTime { get; set; }

        /// <summary>
        /// Trạng thái đăng ký (Registered, Cancelled)
        /// </summary>
        public string? Status { get; set; }

        /// <summary>
        /// Lý do hủy (nếu có)
        /// </summary>
        public string? CancellationReason { get; set; }

        /// <summary>
        /// Ngày tạo
        /// </summary>
        public DateTime? CreatedDate { get; set; }
    }
}


