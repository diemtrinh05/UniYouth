using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Contracts.DTOs.Events.Qr
{
    /// <summary>
    /// DTO phản hồi khi tạo mới hoặc truy vấn thông tin mã QR của sự kiện.
    /// 
    /// DTO này được sử dụng cho:
    /// - Kết quả trả về sau khi CanBo/Admin tạo QR code
    /// - Hiển thị chi tiết QR code trong màn hình quản lý
    /// 
    /// LƯU Ý BẢO MẬT:
    /// - QRToken chỉ được trả về ở API tạo QR
    /// - Các API danh sách KHÔNG trả về full token
    /// </summary>
    public class EventQrResponseDto
    {
        /// <summary>
        /// ID của QR code (khóa chính trong hệ thống)
        /// </summary>
        public int QRID { get; set; }
        /// <summary>
        /// ID của sự kiện mà QR code này thuộc về
        /// </summary>
        public int EventID { get; set; }
        /// <summary>
        /// Tên sự kiện (phục vụ hiển thị, tránh frontend phải gọi thêm API)
        /// </summary>
        public string EventName { get; set; } = string.Empty;

        /// <summary>
        /// Token bảo mật để nhúng vào QR code
        /// Token này sẽ được sử dụng khi quét QR để điểm danh
        /// </summary>
        public string QRToken { get; set; } = string.Empty;
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
        /// - true  : QR đang được cho phép sử dụng
        /// - false : QR đã bị vô hiệu hóa thủ công
        /// 
        /// Thông thường frontend chỉ cần sử dụng thuộc tính Status.
        /// </summary>
        public bool? IsActive { get; set; }
        /// <summary>
        /// Giới hạn số lần quét QR.
        /// 
        /// - null : không giới hạn số lượt quét
        /// - > 0  : số lượt quét tối đa cho phép
        /// </summary>
        public int? ScanLimit { get; set; }
        /// <summary>
        /// Số lượt quét QR hiện tại
        /// </summary>
        public int? CurrentScans { get; set; }

        /// <summary>
        /// Trạng thái hiệu lực dựa trên thời gian hiện tại
        /// </summary>
        public string Status { get; set; } = string.Empty;// "Đang hoạt động", "Đã hết hạn", "Đã vô hiệu hóa", "Chưa có hiệu lực"
        /// <summary>
        /// Họ tên người đã tạo QR code (CanBo/Admin)
        /// </summary>
        public string CreatedByName { get; set; } = string.Empty;
        /// <summary>
        /// Thời điểm QR code được tạo
        /// </summary>
        public DateTime? CreatedDate { get; set; }
    }
}
