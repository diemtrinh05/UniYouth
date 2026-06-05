using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Events
{
    /// <summary>
    /// DTO dùng để cập nhật thứ tự hiển thị của ảnh sự kiện
    /// </summary>
    public class UpdateEventImageOrderDto
    {
        /// <summary>
        /// Thứ tự hiển thị mới
        /// </summary>
        [Required(ErrorMessage = "Thứ tự hiển thị là bắt buộc")]
        [Range(1, 1000, ErrorMessage = "Thứ tự hiển thị phải từ 1 đến 1000")]
        public int DisplayOrder { get; set; }
    }
}
