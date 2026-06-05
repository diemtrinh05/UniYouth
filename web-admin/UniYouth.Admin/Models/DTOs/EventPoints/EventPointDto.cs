namespace UniYouth.Admin.Models.DTOs.EventPoints
{
    /// <summary>
    /// DTO đại diện cho quy tắc điểm của sự kiện từ API
    /// Mỗi event có thể có nhiều quy tắc điểm cho các vai trò khác nhau
    /// </summary>
    public class EventPointDto
    {
        /// <summary>
        /// ID của quy tắc điểm
        /// </summary>
        public int EventPointID { get; set; }

        /// <summary>
        /// ID sự kiện
        /// </summary>
        public int EventID { get; set; }

        /// <summary>
        /// Vai trò (Organizer, Participant, Volunteer)
        /// Người tham gia với vai trò này sẽ nhận số điểm tương ứng
        /// </summary>
        public string? RoleType { get; set; }

        /// <summary>
        /// Số điểm được cấp
        /// Phải là số nguyên dương
        /// </summary>
        public int Points { get; set; }

        /// <summary>
        /// Mô tả chi tiết (tùy chọn)
        /// Giải thích tại sao vai trò này nhận số điểm như vậy
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// Ngày tạo quy tắc
        /// </summary>
        public DateTime? CreatedDate { get; set; }
    }
}
