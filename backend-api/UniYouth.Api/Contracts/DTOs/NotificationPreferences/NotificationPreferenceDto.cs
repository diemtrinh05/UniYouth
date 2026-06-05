namespace UniYouth.Api.Contracts.DTOs.NotificationPreferences
{
    public sealed class NotificationPreferenceDto
    {
        public int NotificationTypeID { get; set; }

        public string NotificationType { get; set; } = string.Empty;

        public bool IsInAppEnabled { get; set; }

        public bool IsRealtimeEnabled { get; set; }

        public bool IsPushEnabled { get; set; }

        public bool IsMuted { get; set; }

        public string? QuietHoursStart { get; set; }

        public string? QuietHoursEnd { get; set; }

        public DateTime UpdatedDate { get; set; }
    }
}
