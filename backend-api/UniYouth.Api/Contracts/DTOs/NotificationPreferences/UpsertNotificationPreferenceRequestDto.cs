namespace UniYouth.Api.Contracts.DTOs.NotificationPreferences
{
    public sealed class UpsertNotificationPreferenceRequestDto
    {
        public bool IsInAppEnabled { get; set; } = true;

        public bool IsRealtimeEnabled { get; set; } = true;

        public bool IsPushEnabled { get; set; } = true;

        public bool IsMuted { get; set; } = false;

        // HH:mm (24h), ví dụ "22:00"
        public string? QuietHoursStart { get; set; }

        // HH:mm (24h), ví dụ "07:00"
        public string? QuietHoursEnd { get; set; }
    }
}
