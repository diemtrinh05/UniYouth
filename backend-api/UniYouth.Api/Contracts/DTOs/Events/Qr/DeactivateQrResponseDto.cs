namespace UniYouth.Api.Contracts.DTOs.Events.Qr
{
    /// <summary>
    /// DTO phản hồi sau khi vô hiệu hóa (deactivate) mã QR của sự kiện.
    /// 
    /// DTO này được sử dụng để xác nhận rằng:
    /// - Mã QR đã được thu hồi quyền sử dụng thành công
    /// - QR code không còn hợp lệ cho việc quét và điểm danh
    /// 
    /// Thường được trả về sau khi CanBo/Admin thực hiện thao tác
    /// vô hiệu hóa QR code từ màn hình quản lý.
    /// </summary>
    public class DeactivateQrResponseDto
    {
        /// <summary>
        /// Kết quả của thao tác vô hiệu hóa
        /// 
        /// - true  : Vô hiệu hóa thành công
        /// - false : Thao tác không thành công
        /// </summary>
        public bool Success { get; set; }
        /// <summary>
        /// Thông báo kết quả thao tác, dùng để hiển thị cho người dùng.
        /// 
        /// Ví dụ:
        /// - "QR code đã được vô hiệu hóa thành công"
        /// - "QR code đã ở trạng thái vô hiệu hóa"
        /// </summary>
        public string Message { get; set; } = string.Empty;
        /// <summary>
        /// ID của QR code đã bị vô hiệu hóa
        /// </summary>
        public int QRID { get; set; }
        /// <summary>
        /// Thời điểm QR code bị vô hiệu hóa
        /// 
        /// Giá trị này thường là thời gian hệ thống (UTC)
        /// để phục vụ việc audit và theo dõi lịch sử thao tác.
        /// </summary>
        public DateTime DeactivatedAt { get; set; }
    }
}
