namespace UniYouth.Admin.Models.DTOs.EventPoints
{
    /// <summary>
    /// DTO cho request cập nhật quy tắc điểm
    /// </summary>
    public class UpdateEventPointRequestDto
    {
        /// <summary>
        /// Số điểm mới - phải từ 1 đến 2147483647
        /// </summary>
        public int Points { get; set; }

        /// <summary>
        /// Mô tả mới (tùy chọn) - tối đa 255 ký tự
        /// </summary>
        public string? Description { get; set; }
    }
}
