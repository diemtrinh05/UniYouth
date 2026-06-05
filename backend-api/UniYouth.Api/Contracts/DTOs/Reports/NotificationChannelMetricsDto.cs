namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class NotificationChannelMetricsDto
    {
        public byte Channel { get; set; }
        public string ChannelName { get; set; } = string.Empty;
        public int Attempts { get; set; }
        public int Success { get; set; }
        public int Failed { get; set; }
        public decimal SuccessRate { get; set; }
    }
}
