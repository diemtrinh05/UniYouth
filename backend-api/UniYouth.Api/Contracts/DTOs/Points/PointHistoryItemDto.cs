namespace UniYouth.Api.Contracts.DTOs.Points
{
    /// <summary>
    /// DTO đại diện cho một bản ghi trong lịch sử cộng / trừ điểm
    /// 
    /// ĐƯỢC SỬ DỤNG KHI:
    /// - Người dùng xem lịch sử điểm rèn luyện của mình
    /// - Admin / cán bộ kiểm tra lại quá trình cộng điểm
    /// 
    /// Mỗi bản ghi tương ứng với một lần cộng hoặc trừ điểm.
    /// </summary>
    public class PointHistoryItemDto
    {
        public int PointID { get; set; }
        public int EventID { get; set; }
        public string EventName { get; set; } = string.Empty;
        public DateTime EventStartTime { get; set; }
        public int Points { get; set; }
        /// <summary>
        /// Loại điểm
        /// 
        /// Ví dụ:
        /// - Attendance : Điểm danh
        /// - Bonus      : Điểm thưởng
        /// - Penalty    : Điểm trừ
        /// </summary>
        public string? PointType { get; set; } = string.Empty; // Attendance, Bonus, Penalty
        public string? RoleType { get; set; } // Participant, Organizer, Volunteer
        /// <summary>
        /// Tên người thực hiện cộng / trừ điểm
        /// 
        /// - NULL hoặc "Hệ thống" : Cộng điểm tự động
        /// - Có giá trị          : Cộng điểm thủ công bởi Admin / Cán bộ
        /// </summary>
        public string? AwardedByName { get; set; } // NULL nếu automatic
        public DateTime? CreatedDate { get; set; }
    }
}
