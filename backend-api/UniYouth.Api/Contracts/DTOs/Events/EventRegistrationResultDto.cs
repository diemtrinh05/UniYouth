namespace UniYouth.Api.Contracts.DTOs.Events
{
    /// <summary>
    /// DTO trả về kết quả đăng ký hoặc hủy đăng ký tham gia sự kiện
    /// 
    /// Được sử dụng trong các API:
    /// - Đăng ký sự kiện
    /// - Hủy đăng ký sự kiện
    /// - Lấy thông tin đăng ký của người dùng
    /// </summary>
    public class EventRegistrationResultDto
    {
        /// <summary>
        /// ID của bản ghi đăng ký sự kiện
        /// </summary>
        public int RegistrationID { get; set; }
        /// <summary>
        /// ID của sự kiện
        /// </summary>
        public int EventID { get; set; }
        /// <summary>
        /// Tên sự kiện mà người dùng đăng ký
        /// </summary>
        public string EventName { get; set; } = string.Empty;
        /// <summary>
        /// ID của người dùng (đoàn viên / hội viên)
        /// </summary>
        public int UserID { get; set; }
        /// <summary>
        /// Họ và tên đầy đủ của người dùng
        /// </summary>
        public string UserFullName { get; set; } = string.Empty;
        /// <summary>
        /// Thời điểm người dùng thực hiện đăng ký sự kiện
        /// </summary>
        public DateTime? RegisterTime { get; set; }
        /// <summary>
        /// Trạng thái đăng ký của người dùng đối với sự kiện
        /// - "Đã đăng ký": đang tham gia sự kiện
        /// - "Đã hủy": đã hủy đăng ký tham gia
        /// </summary>
        public string? Status { get; set; } = string.Empty; 
        /// <summary>
        /// Lý do hủy đăng ký (chỉ có giá trị khi trạng thái là "Đã hủy")
        /// </summary>
        public string? CancellationReason { get; set; }
        /// <summary>
        /// Thời điểm tạo bản ghi đăng ký
        /// </summary>
        public DateTime? CreatedDate { get; set; }
    }

    /// <summary>
    /// DTO dùng cho yêu cầu hủy đăng ký sự kiện
    /// 
    /// Được gửi kèm trong body của API DELETE (không bắt buộc),
    /// cho phép người dùng cung cấp lý do hủy đăng ký.
    /// </summary>
    public class CancelRegistrationRequestDto
    {
        /// <summary>
        /// Lý do người dùng hủy đăng ký tham gia sự kiện (tùy chọn)
        /// </summary>
        public string? CancellationReason { get; set; }
    }

    /// <summary>
    /// DTO bao bọc kết quả trả về của các API đăng ký / hủy đăng ký sự kiện
    /// 
    /// Giúp frontend dễ xử lý:
    /// - Xác định thao tác có thành công hay không
    /// - Hiển thị thông báo phù hợp cho người dùng
    /// </summary>
    public class RegistrationSummaryDto
    {
        /// <summary>
        /// Trạng thái xử lý của yêu cầu (true: thành công, false: thất bại)
        /// </summary>
        public bool Success { get; set; }
        /// <summary>
        /// Thông báo kết quả xử lý, dùng để hiển thị cho người dùng
        /// </summary>
        public string Message { get; set; } = string.Empty;
        /// <summary>
        /// Dữ liệu chi tiết về đăng ký sự kiện (nếu có)
        /// </summary>
        public EventRegistrationResultDto? Data { get; set; }
    }
}
