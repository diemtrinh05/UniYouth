namespace UniYouth.Admin.Models.DTOs.QrCodes
{
    /// <summary>
    /// DTO đại diện cho thông tin QR Code từ API
    /// Được sử dụng khi lấy danh sách QR codes của sự kiện
    /// </summary>
    public class EventQrListItemDto
    {
        /// <summary>
        /// ID của QR Code
        /// </summary>
        public int Qrid { get; set; }

        /// <summary>
        /// ID của sự kiện
        /// </summary>
        public int EventID { get; set; }

        /// <summary>
        /// Preview token (không hiển thị full token vì lý do bảo mật)
        /// </summary>
        public string? QrTokenPreview { get; set; }

        /// <summary>
        /// Thời gian bắt đầu hiệu lực
        /// </summary>
        public DateTime ValidFrom { get; set; }

        /// <summary>
        /// Thời gian hết hiệu lực
        /// </summary>
        public DateTime ValidUntil { get; set; }

        /// <summary>
        /// QR code có đang active không
        /// </summary>
        public bool? IsActive { get; set; }

        /// <summary>
        /// Giới hạn số lần scan (null = không giới hạn)
        /// </summary>
        public int? ScanLimit { get; set; }

        /// <summary>
        /// Số lần đã scan
        /// </summary>
        public int? CurrentScans { get; set; }

        /// <summary>
        /// Trạng thái hiển thị (Active, Expired, Deactivated, etc.)
        /// </summary>
        public string? Status { get; set; }

        /// <summary>
        /// Tên người tạo QR
        /// </summary>
        public string? CreatedByName { get; set; }

        /// <summary>
        /// Ngày tạo QR
        /// </summary>
        public DateTime? CreatedDate { get; set; }
    }
}
