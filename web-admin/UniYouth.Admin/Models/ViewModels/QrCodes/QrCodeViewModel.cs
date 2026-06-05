using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.QrCodes
{
    /// <summary>
    /// ViewModel đại diện cho một QR Code trong danh sách
    /// </summary>
    public class QrCodeViewModel
    {
        public int QrId { get; set; }

        [Display(Name = "Event ID")]
        public int EventId { get; set; }

        [Display(Name = "QR Token")]
        public string QrTokenPreview { get; set; } = string.Empty;

        /// <summary>
        /// Full token - chỉ có khi mới tạo
        /// </summary>
        public string? QrTokenFull { get; set; }

        [Display(Name = "Hiệu lực từ")]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy HH:mm}")]
        public DateTime ValidFrom { get; set; }

        [Display(Name = "Hiệu lực đến")]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy HH:mm}")]
        public DateTime ValidUntil { get; set; }

        [Display(Name = "Trạng thái")]
        public bool IsActive { get; set; }

        [Display(Name = "Giới hạn Scan")]
        public int? ScanLimit { get; set; }

        [Display(Name = "Đã Scan")]
        public int CurrentScans { get; set; }

        [Display(Name = "Trạng thái")]
        public string Status { get; set; } = string.Empty;

        [Display(Name = "Người tạo")]
        public string? CreatedByName { get; set; }

        [Display(Name = "Ngày tạo")]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy HH:mm}")]
        public DateTime? CreatedDate { get; set; }

        /// <summary>
        /// Helper: Kiểm tra QR đã hết hạn chưa
        /// </summary>
        public bool IsExpired => DateTime.Now > ValidUntil;

        /// <summary>
        /// Helper: Kiểm tra QR đã đạt giới hạn scan chưa
        /// </summary>
        public bool IsLimitReached => ScanLimit.HasValue && CurrentScans >= ScanLimit.Value;

        /// <summary>
        /// Helper: Kiểm tra có thể deactivate không
        /// </summary>
        public bool CanDeactivate => IsActive && !IsExpired;

        /// <summary>
        /// Helper: Badge class cho status
        /// </summary>
        public string StatusBadgeClass => Status switch
        {
            "Active" => "bg-success",
            "Expired" => "bg-secondary",
            "Deactivated" => "bg-danger",
            "LimitReached" => "bg-warning",
            _ => "bg-secondary"
        };

        /// <summary>
        /// Helper: Icon cho status
        /// </summary>
        public string StatusIcon => Status switch
        {
            "Active" => "bi-check-circle-fill",
            "Expired" => "bi-clock-history",
            "Deactivated" => "bi-x-circle-fill",
            "LimitReached" => "bi-exclamation-triangle-fill",
            _ => "bi-question-circle"
        };
    }

}
