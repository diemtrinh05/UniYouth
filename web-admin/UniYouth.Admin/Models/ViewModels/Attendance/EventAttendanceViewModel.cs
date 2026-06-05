using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.Attendance
{
    /// <summary>
    /// ViewModel đại diện cho một bản ghi điểm danh
    /// Bao gồm thông tin validation (GPS, thời gian)
    /// 
    /// LÝ DO READ-ONLY:
    /// - Dữ liệu điểm danh đã được validate bởi backend khi check-in
    /// - Admin chỉ cần XEM để kiểm tra, báo cáo, phát hiện gian lận
    /// - KHÔNG cho phép sửa/xóa để đảm bảo tính toàn vẹn dữ liệu
    /// - Nếu cần điều chỉnh, phải thông qua quy trình chính thức (appeal)
    /// </summary>
    public class EventAttendanceViewModel
    {
        public int AttendanceID { get; set; }
        public int UserID { get; set; }

        [Display(Name = "Mã Sinh viên")]
        public string Code { get; set; } = string.Empty;

        [Display(Name = "Họ và Tên")]
        public string FullName { get; set; } = string.Empty;

        [Display(Name = "Email")]
        public string Email { get; set; } = string.Empty;

        [Display(Name = "Thời gian Check-in")]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy HH:mm:ss}")]
        public DateTime CheckInTime { get; set; }

        [Display(Name = "Phương thức")]
        public string CheckInMethod { get; set; } = string.Empty;

        [Display(Name = "Hợp lệ")]
        public bool IsValid { get; set; }

        [Display(Name = "Lý do Không hợp lệ")]
        public string? InvalidReason { get; set; }

        [Display(Name = "Khoảng cách (m)")]
        [DisplayFormat(DataFormatString = "{0:N1}")]
        public double? Distance { get; set; }

        public double? UserLatitude { get; set; }
        public double? UserLongitude { get; set; }
        public string? IpAddress { get; set; }

        [Display(Name = "Thiết bị")]
        public string? DeviceInfo { get; set; }

        [Display(Name = "Client Device ID")]
        public string? ClientDeviceId { get; set; }

        [Display(Name = "Xác minh khuôn mặt")]
        public bool? FaceVerified { get; set; }

        [Display(Name = "Độ tin cậy khuôn mặt")]
        [DisplayFormat(DataFormatString = "{0:P1}")]
        public double? FaceConfidence { get; set; }

        [Display(Name = "Trạng thái face")]
        public string? FaceVerificationStatus { get; set; }

        [Display(Name = "Face provider")]
        public string? FaceVerificationProvider { get; set; }

        [Display(Name = "Face version")]
        public string? FaceVerificationVersion { get; set; }

        [Display(Name = "Face reason")]
        public string? FaceVerificationReason { get; set; }

        [Display(Name = "Điểm rủi ro")]
        public int? RiskScore { get; set; }

        [Display(Name = "Mức rủi ro")]
        public string? RiskLevel { get; set; }

        [Display(Name = "Lý do rủi ro")]
        public List<string> RiskReasons { get; set; } = new();

        /// <summary>
        /// Helper: Badge class cho validity
        /// Valid = xanh lá (success)
        /// Invalid = đỏ (danger)
        /// </summary>
        public string ValidityBadgeClass => IsValid ? "bg-success" : "bg-danger";

        /// <summary>
        /// Helper: Icon cho validity
        /// </summary>
        public string ValidityIcon => IsValid ? "bi-check-circle-fill" : "bi-x-circle-fill";

        /// <summary>
        /// Helper: Display text cho validity
        /// </summary>
        public string ValidityDisplay => IsValid ? "Hợp lệ" : "Không hợp lệ";

        /// <summary>
        /// Helper: Row class cho table highlighting
        /// Valid attendances = light green background
        /// Invalid attendances = light red background
        /// </summary>
        public string TableRowClass => IsValid ? "table-success" : "table-danger";

        /// <summary>
        /// Helper: Format distance cho display
        /// </summary>
        public string DistanceDisplay
        {
            get
            {
                if (Distance.HasValue)
                {
                    if (Distance.Value < 1000)
                        return $"{Distance.Value:N1} m";
                    else
                        return $"{(Distance.Value / 1000):N2} km";
                }
                return "N/A";
            }
        }

        /// <summary>
        /// Helper: Badge class cho check-in method
        /// </summary>
        public string MethodBadgeClass => CheckInMethod?.ToLower() switch
        {
            "qr" => "bg-primary",
            "manual" => "bg-warning",
            "gps" => "bg-info",
            _ => "bg-secondary"
        };

        public string FaceVerificationBadgeClass => FaceVerificationStatus?.ToLowerInvariant() switch
        {
            "matched" => "bg-success",
            "review" => "bg-warning text-dark",
            "mismatch" => "bg-danger",
            "profilemissing" => "bg-secondary",
            "notrequested" => "bg-light text-dark border",
            "nofacedetected" => "bg-warning text-dark",
            "multiplefacesdetected" => "bg-warning text-dark",
            "blurryimage" => "bg-warning text-dark",
            "invalidpayload" => "bg-warning text-dark",
            "technicalerror" => "bg-secondary",
            _ => "bg-light text-dark border"
        };

        public string FaceVerificationDisplay => FaceVerificationStatus switch
        {
            "Matched" => "Đã khớp",
            "Review" => "Cần rà soát",
            "Mismatch" => "Không khớp",
            "ProfileMissing" => "Thiếu hồ sơ",
            "NoFaceDetected" => "Không thấy mặt",
            "MultipleFacesDetected" => "Nhiều khuôn mặt",
            "BlurryImage" => "Ảnh mờ",
            "InvalidPayload" => "Payload lỗi",
            "TechnicalError" => "Lỗi kỹ thuật",
            "NotRequested" => "Không yêu cầu",
            null or "" => "Chưa có",
            _ => FaceVerificationStatus
        };

        public string FaceVerificationIcon => FaceVerificationStatus?.ToLowerInvariant() switch
        {
            "matched" => "bi-person-check-fill",
            "review" => "bi-exclamation-circle-fill",
            "mismatch" => "bi-person-x-fill",
            "profilemissing" => "bi-person-dash-fill",
            "technicalerror" => "bi-tools",
            "notrequested" => "bi-dash-circle",
            "nofacedetected" => "bi-camera-video-off-fill",
            "multiplefacesdetected" => "bi-people-fill",
            "blurryimage" => "bi-image-alt",
            "invalidpayload" => "bi-file-earmark-x-fill",
            _ => "bi-person-bounding-box"
        };

        public string FaceConfidenceDisplay => FaceConfidence.HasValue
            ? $"{FaceConfidence.Value:P1}"
            : "N/A";

        public string FaceVerifiedDisplay => FaceVerified switch
        {
            true => "Có",
            false => "Không",
            null => "N/A"
        };

        public string FaceVerificationProviderDisplay => string.IsNullOrWhiteSpace(FaceVerificationProvider)
            ? "-"
            : FaceVerificationProvider;

        public string FaceVerificationVersionDisplay => string.IsNullOrWhiteSpace(FaceVerificationVersion)
            ? "-"
            : FaceVerificationVersion;

        public string FaceVerificationReasonDisplay => string.IsNullOrWhiteSpace(FaceVerificationReason)
            ? "-"
            : FaceVerificationReason;

        public string RiskLevelBadgeClass => RiskLevel?.ToLowerInvariant() switch
        {
            "low" => "bg-success",
            "medium" => "bg-warning text-dark",
            "high" => "bg-danger",
            "critical" => "bg-dark text-danger-emphasis border border-danger",
            _ => "bg-light text-dark border"
        };

        public string RiskLevelDisplay => RiskLevel switch
        {
            "Low" => "Thấp",
            "Medium" => "Trung bình",
            "High" => "Cao",
            "Critical" => "Nghiêm trọng",
            null or "" => "Chưa có",
            _ => RiskLevel
        };

        public string RiskIcon => RiskLevel?.ToLowerInvariant() switch
        {
            "low" => "bi-shield-check",
            "medium" => "bi-exclamation-triangle",
            "high" => "bi-shield-exclamation",
            "critical" => "bi-fire",
            _ => "bi-dash-circle"
        };

        public string RiskScoreDisplay => RiskScore?.ToString() ?? "N/A";

        public string RiskReasonsDisplay => RiskReasons.Count > 0
            ? string.Join("; ", RiskReasons)
            : "Không có";

        public bool IsSuspicious => RiskScore.GetValueOrDefault() > 0;

        public bool NeedsManualReview => FaceVerificationStatus?.ToLowerInvariant() switch
        {
            "review" => true,
            "mismatch" => true,
            "profilemissing" => true,
            "nofacedetected" => true,
            "multiplefacesdetected" => true,
            "blurryimage" => true,
            "invalidpayload" => true,
            "technicalerror" => true,
            _ => IsSuspicious
        };

        public string ReviewFocusDisplay => FaceVerificationStatus?.ToLowerInvariant() switch
        {
            "review" => "Đối chiếu ảnh tham chiếu và ảnh probe vì hệ thống chưa đủ chắc chắn để auto-pass.",
            "mismatch" => "Ưu tiên xác minh khả năng check-in sai người hoặc dùng ảnh không khớp hồ sơ.",
            "profilemissing" => "Người dùng chưa có face profile usable; cần kiểm tra lại hồ sơ khuôn mặt.",
            "nofacedetected" => "Ảnh gửi lên không phát hiện được khuôn mặt; cần xem lại ảnh capture.",
            "multiplefacesdetected" => "Ảnh chứa nhiều khuôn mặt; cần kiểm tra lại cách chụp và môi trường.",
            "blurryimage" => "Ảnh mờ; cần kiểm tra chất lượng ảnh và yêu cầu chụp lại nếu cần.",
            "invalidpayload" => "Payload ảnh lỗi; cần kiểm tra app/request đã gửi lên.",
            "technicalerror" => "Lỗi kỹ thuật hoặc timeout; cần kiểm tra log ML service trước khi kết luận gian lận.",
            _ when IsSuspicious => "Kiểm tra thêm IP, thiết bị và các lý do rủi ro trước khi kết luận.",
            _ => "Không có tín hiệu cần review bổ sung."
        };
    }
}

