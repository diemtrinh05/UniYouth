namespace UniYouth.Admin.Models.DTOs.QrCodes
{
    /// <summary>
    /// DTO cho request tạo QR code
    /// </summary>
    public class GenerateEventQrRequestDto
    {
        /// <summary>
        /// Thời gian bắt đầu hiệu lực
        /// </summary>
        public DateTime ValidFrom { get; set; }

        /// <summary>
        /// Thời gian hết hiệu lực
        /// </summary>
        public DateTime ValidUntil { get; set; }

        /// <summary>
        /// Giới hạn số lần scan (tùy chọn)
        /// null = không giới hạn
        /// </summary>
        public int? ScanLimit { get; set; }
    }
}
