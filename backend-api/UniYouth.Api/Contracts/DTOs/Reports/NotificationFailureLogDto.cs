namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class NotificationFailureLogDto
    {
        public int DeliveryLogID { get; set; }
        public int OutboxID { get; set; }
        public int NotificationID { get; set; }
        public int UserID { get; set; }
        public byte Channel { get; set; }
        public string ChannelName { get; set; } = string.Empty;
        public int AttemptNumber { get; set; }
        public string? ErrorMessage { get; set; }
        public DateTime? CreatedDate { get; set; }
    }
}
