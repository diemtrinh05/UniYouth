namespace UniYouth.Admin.Models.DTOs.EventPoints
{
    /// <summary>
    /// DTO cho request tạo quy tắc điểm mới
    /// </summary>
    public class CreateEventPointRequestDto
    {
        /// <summary>
        /// Vai trò - phải là một trong: Organizer, Participant, Volunteer
        /// </summary>
        public string RoleType { get; set; } = string.Empty;

        /// <summary>
        /// Số điểm - phải từ 1 đến 2147483647
        /// </summary>
        public int Points { get; set; }

        /// <summary>
        /// Mô tả (tùy chọn) - tối đa 255 ký tự
        /// </summary>
        public string? Description { get; set; }
    }
}
