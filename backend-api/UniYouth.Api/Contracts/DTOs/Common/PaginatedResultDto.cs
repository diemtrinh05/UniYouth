namespace UniYouth.Api.Contracts.DTOs.Common
{
    /// <summary>
    /// DTO dùng để bao bọc kết quả phân trang (generic)
    /// Được sử dụng cho các API trả về danh sách có phân trang
    /// </summary>
    /// <typeparam name="T">Kiểu dữ liệu của các phần tử trong danh sách</typeparam>
    public class PaginatedResultDto<T>
    {
        /// <summary>
        /// Danh sách dữ liệu của trang hiện tại
        /// </summary>
        public List<T> Items { get; set; } = new();

        /// <summary>
        /// Tổng số bản ghi của toàn bộ dữ liệu
        /// </summary>
        public int TotalCount { get; set; }

        /// <summary>
        /// Số trang hiện tại (bắt đầu từ 1)
        /// </summary>
        public int PageNumber { get; set; }

        /// <summary>
        /// Số bản ghi trên mỗi trang
        /// </summary>
        public int PageSize { get; set; }

        /// <summary>
        /// Tổng số trang
        /// </summary>
        public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);

        /// <summary>
        /// Có trang trước hay không
        /// </summary>
        public bool HasPreviousPage => PageNumber > 1;

        /// <summary>
        /// Có trang tiếp theo hay không
        /// </summary>
        public bool HasNextPage => PageNumber < TotalPages;
    }
}
