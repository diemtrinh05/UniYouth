namespace UniYouth.Admin.Models.DTOs.Events.Responses
{
    /// <summary>
    /// Response từ API endpoint GET /api/Events
    /// Chứa danh sách events và thông tin phân trang
    /// </summary>
    public class EventListResponse
    {
        public List<EventListItemDto> Items { get; set; } = new();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalPages { get; set; }
        public bool HasPreviousPage { get; set; }
        public bool HasNextPage { get; set; }
    }
}
