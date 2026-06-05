namespace UniYouth.Api.Contracts.DTOs.Events
{
    /// <summary>
    /// DTO dùng cho phản hồi khi upload hình ảnh sự kiện
    /// Trả về danh sách các ảnh đã được tải lên thành công
    /// </summary>
    public class UploadEventImageResponseDto
    {
        /// <summary>
        /// Số lượng hình ảnh được tải lên thành công
        /// </summary>
        public int UploadedCount { get; set; }

        /// <summary>
        /// Danh sách các hình ảnh đã tải lên kèm thông tin chi tiết
        /// </summary>
        public List<EventImagesDto> Images { get; set; } = new();

        /// <summary>
        /// Thông báo bổ sung (nếu có)
        /// </summary>
        public string? Message { get; set; }
    }

}
