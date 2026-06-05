namespace UniYouth.Api.Contracts.DTOs.Events
{
    /// <summary>
    /// DTO dùng để chứa thông tin hình ảnh của sự kiện
    /// Được sử dụng trong các API GET
    /// </summary>
    public class EventImagesDto
    {
        /// <summary>
        /// ID của hình ảnh
        /// </summary>
        public int ImageId { get; set; }

        /// <summary>
        /// ID của sự kiện
        /// </summary>
        public int EventId { get; set; }

        /// <summary>
        /// Đường dẫn URL công khai của hình ảnh
        /// Ví dụ: "/uploads/events/5/event_5_abc123.jpg"
        /// </summary>
        public string ImageUrl { get; set; } = string.Empty;

        /// <summary>
        /// Loại hình ảnh (Banner, Gallery, Thumbnail)
        /// </summary>
        public string? ImageType { get; set; }

        /// <summary>
        /// Chú thích / mô tả cho hình ảnh
        /// </summary>
        public string? Caption { get; set; }

        /// <summary>
        /// Thứ tự hiển thị (dùng để sắp xếp)
        /// </summary>
        public int? DisplayOrder { get; set; }

        /// <summary>
        /// Ngày tải hình ảnh lên hệ thống
        /// </summary>
        public DateTime? CreatedDate { get; set; }
    }
}
