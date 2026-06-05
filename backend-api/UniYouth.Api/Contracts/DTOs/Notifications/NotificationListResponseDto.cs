namespace UniYouth.Api.Contracts.DTOs.Notifications
{
    /// <summary>
    /// DTO cho phản hồi danh sách thông báo có phân trang.
    /// Bao gồm metadata để frontend có thể xử lý pagination.
    /// </summary>
    public class NotificationListResponseDto
    {
        /// <summary>
        /// Danh sách thông báo trong trang hiện tại
        /// </summary>
        public List<NotificationDto> Notifications { get; set; } = new();

        /// <summary>
        /// Tổng số thông báo
        /// </summary>
        public int TotalCount { get; set; }

        /// <summary>
        /// Số trang hiện tại
        /// </summary>
        public int PageNumber { get; set; }

        /// <summary>
        /// Số lượng item trên mỗi trang
        /// </summary>
        public int PageSize { get; set; }

        /// <summary>
        /// Tổng số trang
        /// </summary>
        public int TotalPages { get; set; }

        /// <summary>
        /// Có trang trước không
        /// </summary>
        public bool HasPreviousPage { get; set; }

        /// <summary>
        /// Có trang tiếp theo không
        /// </summary>
        public bool HasNextPage { get; set; }

        /// <summary>
        /// Tổng số thông báo chưa đọc
        /// Dùng để hiển thị badge/counter trên UI
        /// </summary>
        public int UnreadCount { get; set; }
    }
}
