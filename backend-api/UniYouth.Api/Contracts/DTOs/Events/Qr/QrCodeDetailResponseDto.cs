namespace UniYouth.Api.Contracts.DTOs.Events.Qr
{
    public class QrCodeDetailResponseDto
    {
        public int QrId { get; set; }

        public int EventId { get; set; }

        public string EventName { get; set; } = string.Empty;

        public string QrToken { get; set; } = string.Empty;

        public bool IsActive { get; set; }

        public DateTime ValidFrom { get; set; }

        public DateTime ValidUntil { get; set; }

        public int? ScanLimit { get; set; }

        public int CurrentScans { get; set; }

        public QrCodeCreatorDto CreatedBy { get; set; } = new();

        public DateTime? CreatedDate { get; set; }

        public bool IsExpired { get; set; }

        public bool IsOverScanLimit { get; set; }
    }
}

