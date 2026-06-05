namespace UniYouth.Admin.Models.DTOs.QrCodes
{
    /// <summary>
    /// DTO cho response khi tạo QR code mới
    /// </summary>
    public class EventQrResponseDto
    {
        public int Qrid { get; set; }
        public int EventID { get; set; }
        public string? EventName { get; set; }

        /// <summary>
        /// Full QR token (chỉ hiển thị khi mới tạo)
        /// </summary>
        public string? QrToken { get; set; }

        public DateTime ValidFrom { get; set; }
        public DateTime ValidUntil { get; set; }
        public bool? IsActive { get; set; }
        public int? ScanLimit { get; set; }
        public int? CurrentScans { get; set; }
        public string? Status { get; set; }
        public string? CreatedByName { get; set; }
        public DateTime? CreatedDate { get; set; }
    }
}
