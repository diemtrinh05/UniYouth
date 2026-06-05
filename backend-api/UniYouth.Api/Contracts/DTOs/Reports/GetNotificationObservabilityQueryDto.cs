namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class GetNotificationObservabilityQueryDto
    {
        public DateTime? From { get; set; }

        public DateTime? To { get; set; }

        // 1 = Realtime, 2 = Push
        public byte? Channel { get; set; }

        public int TopFailures { get; set; } = 20;
    }
}
