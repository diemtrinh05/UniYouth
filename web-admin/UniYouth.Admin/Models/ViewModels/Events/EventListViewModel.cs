namespace UniYouth.Admin.Models.ViewModels.Events
{
    /// <summary>
    /// ViewModel cho trang danh sách Events
    /// 
    /// TẠI SAO DÙNG VIEWMODEL THAY VÌ DTO:
    /// - ViewModels được thiết kế riêng cho UI/UX
    /// - DTOs là contract với API (không nên thay đổi)
    /// - ViewModels có thể có thêm properties cho UI (như StatusBadgeClass)
    /// - ViewModels có validation attributes phù hợp với form
    /// - Tách biệt concerns: API layer vs Presentation layer
    /// </summary>
    public class EventListViewModel
    {
        public List<EventListItemViewModel> Events { get; set; } = new();
        public int TotalCount { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalPages { get; set; }
        public bool HasPreviousPage { get; set; }
        public bool HasNextPage { get; set; }

        // Stats (computed from the full filtered result-set, not just current page)
        public int UpcomingCount { get; set; }
        public int OngoingCount { get; set; }
        public int ClosedCount { get; set; }
        public int CancelledCount { get; set; }
        public int TotalParticipants { get; set; }
    }
}
