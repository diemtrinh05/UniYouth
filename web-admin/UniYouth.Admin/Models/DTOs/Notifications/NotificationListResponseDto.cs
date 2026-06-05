using System.Text.Json.Serialization;

namespace UniYouth.Admin.Models.DTOs.Notifications
{
    public class NotificationListResponseDto
    {
        [JsonPropertyName("notifications")]
        public List<NotificationDto>? Notifications { get; set; }

        [JsonPropertyName("totalCount")]
        public int TotalCount { get; set; }

        [JsonPropertyName("pageNumber")]
        public int PageNumber { get; set; }

        [JsonPropertyName("pageSize")]
        public int PageSize { get; set; }

        [JsonPropertyName("totalPages")]
        public int TotalPages { get; set; }

        [JsonPropertyName("hasPreviousPage")]
        public bool HasPreviousPage { get; set; }

        [JsonPropertyName("hasNextPage")]
        public bool HasNextPage { get; set; }

        [JsonPropertyName("unreadCount")]
        public int UnreadCount { get; set; }
    }
}
