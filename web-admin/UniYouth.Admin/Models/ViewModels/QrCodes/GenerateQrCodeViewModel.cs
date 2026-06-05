using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.QrCodes
{
    /// <summary>
    /// ViewModel cho form tạo QR Code mới
    /// </summary>
    public class GenerateQrCodeViewModel
    {
        /// <summary>
        /// Thời gian bắt đầu hiệu lực
        /// Mặc định = giờ hiện tại
        /// </summary>
        [Required(ErrorMessage = "Vui lòng chọn thời gian bắt đầu")]
        [Display(Name = "Hiệu lực từ")]
        public DateTime? ValidFrom { get; set; } = DateTime.Now;

        /// <summary>
        /// Thời gian hết hiệu lực
        /// Mặc định = 2 giờ sau
        /// </summary>
        [Required(ErrorMessage = "Vui lòng chọn thời gian kết thúc")]
        [Display(Name = "Hiệu lực đến")]
        public DateTime? ValidUntil { get; set; } = DateTime.Now.AddHours(2);

        /// <summary>
        /// Giới hạn số lần scan (tùy chọn)
        /// null = không giới hạn
        /// </summary>
        [Display(Name = "Giới hạn số lần Scan (Tùy chọn)")]
        [Range(1, 10000, ErrorMessage = "Giới hạn phải từ 1 đến 10,000")]
        public int? ScanLimit { get; set; }

        /// <summary>
        /// Validation: ValidFrom phải trước ValidUntil
        /// </summary>
        public bool IsValid => ValidFrom.HasValue && ValidUntil.HasValue && ValidFrom.Value < ValidUntil.Value;

        /// <summary>
        /// Helper: Tính duration
        /// </summary>
        public TimeSpan Duration =>
            ValidFrom.HasValue && ValidUntil.HasValue
                ? ValidUntil.Value - ValidFrom.Value
                : TimeSpan.Zero;

        /// <summary>
        /// Helper: Format duration cho display
        /// </summary>
        public string DurationDisplay
        {
            get
            {
                var duration = Duration;
                if (duration.TotalDays >= 1)
                    return $"{duration.Days} ngày {duration.Hours} giờ";
                if (duration.TotalHours >= 1)
                    return $"{duration.Hours} giờ {duration.Minutes} phút";
                return $"{duration.Minutes} phút";
            }
        }
    }
    /// <summary>
    /// ViewModel cho thống kê QR Codes
    /// Sử dụng trong trang chủ hoặc overview
    /// </summary>
    public class QrCodeStatsViewModel
    {
        public int EventId { get; set; }
        public string EventName { get; set; } = string.Empty;
        public int TotalQrCodes { get; set; }
        public int ActiveQrCodes { get; set; }
        public int TotalScans { get; set; }
        public DateTime? LastGeneratedAt { get; set; }
        public string? LastGeneratedBy { get; set; }
    }
}

