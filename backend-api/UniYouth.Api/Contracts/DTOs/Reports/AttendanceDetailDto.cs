namespace UniYouth.Api.Contracts.DTOs.Reports
{
    /// <summary>
    /// DTO đại diện cho một bản ghi điểm danh chi tiết
    /// 
    /// ĐƯỢC SỬ DỤNG KHI:
    /// - Admin / Cán bộ xem danh sách người đã điểm danh của một sự kiện
    /// - Kiểm tra chi tiết các lượt điểm danh hợp lệ / không hợp lệ
    /// - Phục vụ audit và xử lý các trường hợp bất thường
    /// </summary>
    public class AttendanceDetailDto
    {
        public int AttendanceID { get; set; }
        public int UserID { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public DateTime? CheckInTime { get; set; }
        /// <summary>
        /// Phương thức điểm danh
        /// Ví dụ: QR, QR_GPS, FaceRecognition
        /// </summary>
        public string? CheckInMethod { get; set; } = string.Empty;
        /// <summary>
        /// Trạng thái hợp lệ của lượt điểm danh
        /// - true  : hợp lệ
        /// - false : không hợp lệ (ngoài phạm vi GPS, sai điều kiện, v.v.)
        /// </summary>
        public bool? IsValid { get; set; }
        /// <summary>
        /// Lý do điểm danh không hợp lệ (nếu có)
        /// Chỉ có giá trị khi IsValid = false
        /// </summary>
        public string? InvalidReason { get; set; }
        public double? Distance { get; set; }
        public decimal? UserLatitude { get; set; }
        public decimal? UserLongitude { get; set; }
        public string? IPAddress { get; set; }
        public string? DeviceInfo { get; set; }
        public string? ClientDeviceId { get; set; }
        public bool? FaceVerified { get; set; }
        public double? FaceConfidence { get; set; }
        public string? FaceVerificationStatus { get; set; }
        public string? FaceVerificationProvider { get; set; }
        public string? FaceVerificationVersion { get; set; }
        public string? FaceVerificationReason { get; set; }
        public bool? LivenessPassed { get; set; }
        public double? LivenessScore { get; set; }
        public string? LivenessReason { get; set; }
        public int? RiskScore { get; set; }
        public string? RiskLevel { get; set; }
        public List<string> RiskReasons { get; set; } = new();
    }
}

