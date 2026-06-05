namespace UniYouth.Admin.Models.ViewModels.Notifications
{
    /// <summary>
    /// ViewModel cho trang danh sách thông báo.
    /// Bao gồm danh sách, filter, phân trang và unread count.
    /// </summary>
    public class NotificationListViewModel
    {
        public List<NotificationListItemViewModel> Notifications { get; set; } = new();

        // Filters
        public bool? IsRead { get; set; }
        public int? Priority { get; set; }
        public string? Query { get; set; }

        // Paging + counters
        public int UnreadCount { get; set; }
        public int TotalCount { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;
        public int TotalPages { get; set; } = 1;
        public bool HasPreviousPage { get; set; }
        public bool HasNextPage { get; set; }

        public bool HasNotifications => Notifications.Any();
        public bool HasFilters =>
            IsRead.HasValue ||
            Priority.HasValue ||
            !string.IsNullOrWhiteSpace(Query);
    }
}
