using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Attendance
{
    /// <summary>
    /// DTO request dùng cho chức năng điểm danh (check-in)
    /// 
    /// Client (mobile/web) gửi lên:
    /// - Mã QR đã quét
    /// - Tọa độ GPS hiện tại của người dùng
    /// 
    /// Dữ liệu này sẽ được server dùng để:
    /// - Xác thực mã QR
    /// - Kiểm tra vị trí người dùng có nằm trong phạm vi cho phép hay không
    /// </summary>
    public class CheckInRequestDto
    {
        /// <summary>
        /// Chuỗi token được mã hóa trong QR code
        /// QR code này do Cán bộ hoặc Quản trị viên tạo cho sự kiện
        /// </summary>
        [Required(ErrorMessage = "QR token là bắt buộc")]
        public string QRToken { get; set; } = string.Empty;

        /// <summary>
        /// Vĩ độ (Latitude) GPS của người dùng tại thời điểm điểm danh
        /// Giá trị hợp lệ nằm trong khoảng từ -90 đến 90
        /// </summary>
        [Required(ErrorMessage = "Latitude là bắt buộc")]
        [Range(-90, 90, ErrorMessage = "Latitude phải trong khoảng -90 đến 90")]
        public decimal Latitude { get; set; }

        /// <summary>
        /// Kinh độ (Longitude) GPS của người dùng tại thời điểm điểm danh
        /// Giá trị hợp lệ nằm trong khoảng từ -180 đến 180
        /// </summary>
        [Required(ErrorMessage = "Longitude là bắt buộc")]
        [Range(-180, 180, ErrorMessage = "Longitude phải trong khoảng -180 đến 180")]
        public decimal Longitude { get; set; }

        /// <summary>
        /// Thông tin thiết bị do client gửi lên.
        /// Ví dụ: Android 14 | Samsung S23 | UniYouth 1.0.0
        /// 
        /// Backend ưu tiên dùng giá trị này để lưu DeviceInfo thay vì User-Agent,
        /// vì User-Agent không phản ánh chính xác model máy/app version trên mobile.
        /// </summary>
        [StringLength(255, ErrorMessage = "DeviceInfo không được vượt quá 255 ký tự")]
        public string? DeviceInfo { get; set; }

        /// <summary>
        /// Mã định danh cài đặt ứng dụng trên thiết bị, do app tự sinh và lưu local.
        /// Dùng để audit/risk scoring, thay thế cho ý tưởng lấy MAC address.
        /// </summary>
        [StringLength(128, ErrorMessage = "ClientDeviceId không được vượt quá 128 ký tự")]
        public string? ClientDeviceId { get; set; }

        /// <summary>
        /// Ảnh khuôn mặt dạng Base64, gửi cùng request check-in khi event bật face verification.
        /// Giữ optional để backward compatibility cho event chưa bật face.
        /// </summary>
        public string? FaceImageBase64 { get; set; }

        /// <summary>
        /// MIME type của ảnh khuôn mặt.
        /// Theo policy hiện tại chỉ hỗ trợ image/jpeg khi event bật face verification.
        /// </summary>
        [StringLength(50, ErrorMessage = "FaceImageMimeType không được vượt quá 50 ký tự")]
        public string? FaceImageMimeType { get; set; }

        /// <summary>
        /// Payload liveness burst, chỉ dùng khi client đã triển khai passive liveness.
        /// Giữ optional để backward compatibility.
        /// </summary>
        public LivenessCheckDto? Liveness { get; set; }
    }
}
