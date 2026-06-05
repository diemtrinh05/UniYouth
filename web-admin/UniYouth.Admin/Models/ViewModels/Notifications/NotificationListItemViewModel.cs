namespace UniYouth.Admin.Models.ViewModels.Notifications
{
    /// <summary>
    /// ViewModel đại diện cho 1 thông báo trong danh sách.
    /// </summary>
    public class NotificationListItemViewModel
    {
        public int NotificationId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? NotificationType { get; set; }
        public int? Priority { get; set; }
        public bool IsRead { get; set; }
        public DateTime? ReadDate { get; set; }
        public string? ActionUrl { get; set; }
        public int? EventId { get; set; }
        public string? EventName { get; set; }
        public DateTime? CreatedDate { get; set; }
        public DateTime? ExpiryDate { get; set; }

        public string CreatedDateDisplay => CreatedDate?.ToString("dd/MM/yyyy HH:mm") ?? "-";
        public string ReadDateDisplay => ReadDate?.ToString("dd/MM/yyyy HH:mm") ?? "-";
        public string PriorityDisplay => Priority?.ToString() ?? "-";
    }
}
