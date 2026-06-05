namespace UniYouth.Api.Contracts.DTOs.Points
{
    /// <summary>
    /// DTO trả về thông tin điểm được cộng cho người dùng
    /// 
    /// ĐƯỢC SỬ DỤNG KHI:
    /// - Người dùng check-in sự kiện thành công
    /// - Hệ thống tự động cộng điểm (attendance, bonus, v.v.)
    /// 
    /// DTO này thường được nhúng trong CheckInResultDto
    /// để hiển thị ngay kết quả cộng điểm cho người dùng.
    /// </summary>
    public class PointAwardedDto
    {
        /// <summary>
        /// Số điểm được cộng
        /// </summary>
        public int Points { get; set; }

        /// <summary>
        /// Loại điểm (Attendance, Bonus, Penalty)
        /// </summary>
        public string PointType { get; set; } = string.Empty;

        /// <summary>
        /// Vai trò của người dùng trong sự kiện
        /// 
        /// Ví dụ:
        /// - Participant : Người tham gia
        /// - Organizer   : Ban tổ chức
        /// - Volunteer   : Tình nguyện viên
        /// </summary>
        public string RoleType { get; set; } = string.Empty;

        /// <summary>
        /// Tổng điểm hiện tại sau khi cộng
        /// </summary>
        public int CurrentTotalPoints { get; set; }
    }
}
