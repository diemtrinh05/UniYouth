namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class NotificationObservabilityResponseDto
    {
        public NotificationObservabilitySummaryDto Summary { get; set; } = new();
        public List<NotificationChannelMetricsDto> ChannelMetrics { get; set; } = new();
        public List<NotificationFailureLogDto> RecentFailures { get; set; } = new();
    }
}
