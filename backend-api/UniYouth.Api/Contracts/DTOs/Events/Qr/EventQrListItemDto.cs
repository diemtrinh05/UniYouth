using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Contracts.DTOs.Events.Qr
{
    /// <summary>
    /// DTO dùng để hiển thị danh sách các mã QR của một sự kiện
    /// trong màn hình quản lý dành cho CanBo/Admin.
    /// 
    /// LƯU Ý BẢO MẬT:
    /// - DTO này KHÔNG trả về QRToken đầy đủ
    /// - Chỉ cung cấp bản xem trước (preview) của token
    /// - Tránh nguy cơ lộ token dùng để điểm danh
    /// </summary>
    public class EventQrListItemDto
    {
        /// <summary>
        /// ID của QR code (khóa chính)
        /// </summary>
        public int QRID { get; set; }
        /// <summary>
        /// ID của sự kiện mà QR code này thuộc về
        /// </summary>
        public int EventID { get; set; }

        /// <summary>
        /// Chỉ hiển thị một phần token để tham khảo (vd: "ABC123...XYZ789")
        /// </summary>
        public string QRTokenPreview { get; set; } = string.Empty;
        /// <summary>
        /// Thời điểm bắt đầu hiệu lực của QR code
        /// </summary>
        public DateTime ValidFrom { get; set; }
        /// <summary>
        /// Thời điểm hết hạn của QR code
        /// </summary>
        public DateTime ValidUntil { get; set; }
        /// <summary>
        /// Trạng thái kích hoạt của QR code.
        /// 
        /// - true  : QR code đang được cho phép sử dụng
        /// - false : QR code đã bị vô hiệu hóa thủ công
        /// 
        /// Thông thường frontend nên dựa vào thuộc tính Status
        /// để hiển thị trạng thái chính xác.
        /// </summary>
        public bool? IsActive { get; set; }
        public int? ScanLimit { get; set; }
        public int? CurrentScans { get; set; }
        public string Status { get; set; } = string.Empty;
        /// <summary>
        /// Họ tên người đã tạo QR code (CanBo/Admin)
        /// </summary>
        public string CreatedByName { get; set; } = string.Empty;
        public DateTime? CreatedDate { get; set; }
    }
}
