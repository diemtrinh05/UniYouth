namespace UniYouth.Api.Contracts.DTOs.Events.Points
{
    /// <summary>
    /// DTO đại diện cho cấu hình điểm của sự kiện.
    /// Điểm sự kiện xác định số điểm rèn luyện mà người dùng nhận được dựa trên vai trò của họ trong sự kiện.
    /// Điều này cho phép phân bổ điểm linh hoạt (ví dụ: Ban tổ chức nhận 50 điểm, Người tham gia nhận 10 điểm).
    /// </summary>
    public class EventPointDto
    {
        /// <summary>
        /// Mã định danh duy nhất cho cấu hình điểm sự kiện
        /// </summary>
        public int EventPointID { get; set; }

        /// <summary>
        /// Sự kiện mà cấu hình điểm này thuộc về
        /// </summary>
        public int EventID { get; set; }

        /// <summary>
        /// Loại vai trò xác định phân bổ điểm.
        /// Giá trị hợp lệ: Organizer, Participant, Volunteer
        /// </summary>
        public string RoleType { get; set; } = string.Empty;

        /// <summary>
        /// Số điểm rèn luyện được trao cho vai trò này
        /// </summary>
        public int Points { get; set; }

        /// <summary>
        /// Mô tả về quy tắc điểm (ví dụ: "Điểm tham gia sự kiện")
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// Thời điểm cấu hình này được tạo
        /// </summary>
        public DateTime? CreatedDate { get; set; }
    }
}
