using UniYouth.Api.Contracts.DTOs.Points;

namespace UniYouth.Api.Contracts.DTOs.Attendance
{
    /// <summary>
    /// DTO response trả về sau khi thực hiện điểm danh (check-in)
    /// 
    /// LƯU Ý QUAN TRỌNG:
    /// - IsSuccess: cho biết request có được xử lý thành công hay không
    /// - IsValid: cho biết lượt điểm danh có hợp lệ hay không
    /// 
    /// Trong một số trường hợp:
    /// - Điểm danh KHÔNG hợp lệ (ví dụ: ngoài phạm vi GPS)
    /// - Nhưng hệ thống vẫn ghi nhận và lưu attendance (IsSuccess = true, IsValid = false)
    /// </summary>
    public class CheckInResultDto
    {
        /// <summary>
        /// Check-in có thành công không
        /// true = điểm danh hợp lệ
        /// false = điểm danh không hợp lệ (nhưng vẫn được ghi nhận)
        /// </summary>
        public bool IsSuccess { get; set; }

        /// <summary>
        /// Thông báo kết quả trả về cho người dùng
        /// Ví dụ:
        /// - "Điểm danh thành công"
        /// - "Điểm danh không hợp lệ: Vị trí quá xa"
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// Tên sự kiện
        /// </summary>
        public string EventName { get; set; } = string.Empty;

        /// <summary>
        /// Thời điểm người dùng thực hiện điểm danh
        /// Thời gian theo giờ Việt Nam (UTC+7)
        /// </summary>
        public DateTime CheckInTime { get; set; }

        /// <summary>
        /// Khoảng cách từ vị trí người dùng đến địa điểm sự kiện (meters)
        /// </summary>
        public double Distance { get; set; }

        /// <summary>
        /// Điểm danh có hợp lệ không
        /// Khác với IsSuccess - bản ghi vẫn được lưu dù không hợp lệ
        /// </summary>
        public bool IsValid { get; set; }

        /// <summary>
        /// Lý do điểm danh không hợp lệ (nếu có)
        /// Chỉ có giá trị khi IsValid = false
        /// </summary>
        public string? InvalidReason { get; set; }

        /// <summary>
        /// ID của bản ghi Attendance đã được tạo trong hệ thống
        /// Dùng cho mục đích tra cứu hoặc audit
        /// </summary>
        public int AttendanceID { get; set; }
        /// <summary>
        /// Thông tin điểm được cộng (nếu có)
        /// NULL nếu không cộng điểm
        /// </summary>
        public PointAwardedDto? PointsAwarded { get; set; }

        /// <summary>
        /// Kết quả xác minh khuôn mặt.
        /// true = matched, false = mismatch/review, null = chưa có kết quả hoặc lỗi kỹ thuật/input.
        /// </summary>
        public bool? FaceVerified { get; set; }

        /// <summary>
        /// Độ tin cậy xác minh khuôn mặt đã normalize về thang 0-1.
        /// </summary>
        public double? FaceConfidence { get; set; }

        /// <summary>
        /// Trạng thái xác minh khuôn mặt.
        /// Ví dụ: Matched, Review, Mismatch, NoFaceDetected, MultipleFacesDetected, BlurryImage, ProfileMissing, InvalidPayload, TechnicalError.
        /// </summary>
        public string? FaceVerificationStatus { get; set; }

        /// <summary>
        /// Thông báo user-safe cho kết quả face verification.
        /// </summary>
        public string? FaceVerificationMessage { get; set; }

        /// <summary>
        /// Điểm rủi ro tổng hợp của lượt check-in.
        /// </summary>
        public int? RiskScore { get; set; }

        /// <summary>
        /// Kết quả liveness đã normalize.
        /// true = Passed, false = Failed, null = Review/lỗi mềm/chưa có dữ liệu.
        /// </summary>
        public bool? LivenessPassed { get; set; }

        /// <summary>
        /// Điểm liveness normalize về thang 0-1.
        /// </summary>
        public double? LivenessScore { get; set; }

        /// <summary>
        /// Thông điệp user-safe cho kết quả liveness.
        /// </summary>
        public string? LivenessReason { get; set; }

        /// <summary>
        /// Mức rủi ro tổng hợp của lượt check-in.
        /// Ví dụ: Low, Medium, High, Critical.
        /// </summary>
        public string? RiskLevel { get; set; }
    }
}
