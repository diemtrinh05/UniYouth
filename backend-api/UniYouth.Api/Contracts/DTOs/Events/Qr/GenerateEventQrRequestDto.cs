namespace UniYouth.Api.Contracts.DTOs.Events.Qr
{
    /// <summary>
    /// DTO yêu cầu dùng để tạo mới mã QR cho sự kiện.
    /// 
    /// DTO này được gửi từ phía CanBo/Admin khi:
    /// - Chuẩn bị QR code cho việc điểm danh sự kiện
    /// - Cấu hình thời gian hiệu lực và giới hạn quét (nếu có)
    /// </summary>
    public class GenerateEventQrRequestDto
    {
        /// <summary>
        /// Thời điểm bắt đầu hiệu lực của QR code
        /// </summary>
        public DateTime ValidFrom { get; set; }

        /// <summary>
        /// Thời điểm hết hạn của QR code
        /// </summary>
        public DateTime ValidUntil { get; set; }

        /// <summary>
        /// Giới hạn số lần quét (null = không giới hạn)
        /// </summary>
        public int? ScanLimit { get; set; }
    }
}
