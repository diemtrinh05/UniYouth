namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class NotificationObservabilitySummaryDto
    {
        public DateTime From { get; set; }
        public DateTime To { get; set; }
        public int TotalAttempts { get; set; }
        public int TotalSuccess { get; set; }
        public int TotalFailed { get; set; }
        public int RetryAttempts { get; set; }
        public decimal SuccessRate { get; set; }
        public double AverageDelaySeconds { get; set; }
        public int MaxDelaySeconds { get; set; }
        public int PendingOutboxCount { get; set; }
        public int ProcessingOutboxCount { get; set; }
        public int FailedOutboxCount { get; set; }
        public int GroupedSuppressedCount { get; set; }
        public int ThrottledDeferredCount { get; set; }
    }
}
