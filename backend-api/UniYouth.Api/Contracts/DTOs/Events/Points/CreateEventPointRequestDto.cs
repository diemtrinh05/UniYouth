using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Events.Points
{
    /// <summary>
    /// DTO dùng để tạo mới cấu hình điểm cho một sự kiện.
    /// 
    /// DTO này cho phép cán bộ quản lý (CanBo, Admin) định nghĩa
    /// số điểm rèn luyện mà người dùng nhận được khi tham gia sự kiện,
    /// dựa trên vai trò của họ trong sự kiện đó.
    /// </summary>
    public class CreateEventPointRequestDto
    {
        /// <summary>
        /// Loại vai trò trong sự kiện để áp dụng quy tắc điểm
        /// Must be one of: Organizer, Participant, Volunteer
        /// </summary>
        [Required(ErrorMessage = "RoleType là bắt buộc")]
        [RegularExpression("^(Organizer|Participant|Volunteer)$",
            ErrorMessage = "RoleType phải là một trong: Organizer, Participant, Volunteer")]
        public string RoleType { get; set; } = string.Empty;

        /// <summary>
        /// Số điểm rèn luyện được trao cho người dùng
        /// khi tham gia sự kiện với vai trò tương ứng.
        /// 
        /// Giá trị phải là số nguyên dương (> 0).
        [Required(ErrorMessage = "Points là bắt buộc")]
        [Range(1, int.MaxValue, ErrorMessage = "Points phải là số nguyên dương")]
        public int Points { get; set; }

        /// <summary>
        /// Mô tả bổ sung cho quy tắc điểm
        /// </summary>
        [MaxLength(255, ErrorMessage = "Description không được vượt quá 255 ký tự")]
        public string? Description { get; set; }
    }
}
