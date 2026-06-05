using System.Text.Json.Serialization;

namespace UniYouth.Admin.Models.DTOs.Notifications
{
    public class NotificationDto
    {
        [JsonPropertyName("notificationID")]
        public int NotificationId { get; set; }

        [JsonPropertyName("title")]
        public string? Title { get; set; }

        [JsonPropertyName("content")]
        public string? Content { get; set; }

        [JsonPropertyName("notificationType")]
        public string? NotificationType { get; set; }

        [JsonPropertyName("priority")]
        public int? Priority { get; set; }

        [JsonPropertyName("isRead")]
        public bool? IsRead { get; set; }

        [JsonPropertyName("readDate")]
        public DateTime? ReadDate { get; set; }

        [JsonPropertyName("actionUrl")]
        public string? ActionUrl { get; set; }

        [JsonPropertyName("eventID")]
        public int? EventId { get; set; }

        [JsonPropertyName("eventName")]
        public string? EventName { get; set; }

        [JsonPropertyName("createdDate")]
        public DateTime? CreatedDate { get; set; }

        [JsonPropertyName("expiryDate")]
        public DateTime? ExpiryDate { get; set; }
    }
}
