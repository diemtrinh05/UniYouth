namespace UniYouth.Admin.Models.DTOs.Attendance
{
    /// <summary>
    /// DTO đại diện cho thông tin điểm danh từ API
    /// Bao gồm cả thông tin validation (GPS, thời gian, QR)
    /// </summary>
    public class AttendanceDetailDto
    {
        /// <summary>
        /// ID điểm danh
        /// </summary>
        public int AttendanceID { get; set; }

        /// <summary>
        /// ID người dùng
        /// </summary>
        public int UserID { get; set; }

        /// <summary>
        /// Họ tên đầy đủ
        /// </summary>
        public string? FullName { get; set; }

        /// <summary>
        /// Mã
        /// </summary>
        public string? Code { get; set; }

        /// <summary>
        /// Email
        /// </summary>
        public string? Email { get; set; }

        /// <summary>
        /// Thời gian check-in
        /// </summary>
        public DateTime? CheckInTime { get; set; }

        /// <summary>
        /// Phương thức check-in (QR, Manual, GPS)
        /// </summary>
        public string? CheckInMethod { get; set; }

        /// <summary>
        /// Điểm danh có hợp lệ không
        /// false = vi phạm quy tắc (GPS, thời gian, v.v.)
        /// </summary>
        public bool? IsValid { get; set; }

        /// <summary>
        /// Lý do không hợp lệ (nếu IsValid = false)
        /// Ví dụ: "Vượt quá khoảng cách cho phép", "Ngoài thời gian sự kiện"
        /// </summary>
        public string? InvalidReason { get; set; }

        /// <summary>
        /// Khoảng cách từ vị trí check-in đến vị trí sự kiện (meters)
        /// </summary>
        public double? Distance { get; set; }

        /// <summary>
        /// Vĩ độ GPS của người dùng khi check-in
        /// </summary>
        public double? UserLatitude { get; set; }

        /// <summary>
        /// Kinh độ GPS của người dùng khi check-in
        /// </summary>
        public double? UserLongitude { get; set; }

        /// <summary>
        /// Địa chỉ IP của thiết bị check-in
        /// </summary>
        public string? IpAddress { get; set; }

        /// <summary>
        /// Thông tin thiết bị check-in (User-Agent / device name tuỳ backend)
        /// </summary>
        public string? DeviceInfo { get; set; }

        /// <summary>
        /// Mã định danh client/device do ứng dụng check-in gửi lên
        /// </summary>
        public string? ClientDeviceId { get; set; }

        /// <summary>
        /// Kết quả xác minh khuôn mặt.
        /// true = matched, false = review/mismatch, null = không có kết quả xác minh đáng tin cậy.
        /// </summary>
        public bool? FaceVerified { get; set; }

        /// <summary>
        /// Điểm tin cậy xác minh khuôn mặt đã được normalize về 0-1.
        /// </summary>
        public double? FaceConfidence { get; set; }

        /// <summary>
        /// Trạng thái xác minh khuôn mặt từ backend.
        /// </summary>
        public string? FaceVerificationStatus { get; set; }

        /// <summary>
        /// Nhà cung cấp/pipeline xác minh khuôn mặt.
        /// </summary>
        public string? FaceVerificationProvider { get; set; }

        /// <summary>
        /// Phiên bản pipeline xác minh khuôn mặt.
        /// </summary>
        public string? FaceVerificationVersion { get; set; }

        /// <summary>
        /// Lý do/diễn giải kết quả xác minh khuôn mặt từ backend.
        /// </summary>
        public string? FaceVerificationReason { get; set; }

        /// <summary>
        /// Điểm rủi ro của lượt điểm danh.
        /// </summary>
        public int? RiskScore { get; set; }

        /// <summary>
        /// Mức rủi ro tổng hợp.
        /// </summary>
        public string? RiskLevel { get; set; }

        /// <summary>
        /// Các lý do cấu thành rủi ro.
        /// </summary>
        public List<string> RiskReasons { get; set; } = new();
    }
}


