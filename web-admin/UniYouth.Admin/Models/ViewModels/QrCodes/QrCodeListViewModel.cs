using System.ComponentModel.DataAnnotations;

using UniYouth.Admin.Models.DTOs.QrCodes;

namespace UniYouth.Admin.Models.ViewModels.QrCodes
{
    /// <summary>
    /// ViewModel chính cho trang danh sách QR Codes
    /// </summary>
    public class QrCodeListViewModel
    {
        public int EventId { get; set; }

        [Display(Name = "Tên Sự kiện")]
        public string EventName { get; set; } = string.Empty;

        [Display(Name = "Danh sách QR Codes")]
        public List<QrCodeViewModel> QrCodes { get; set; } = new();

        /// <summary>
        /// QR code vừa được tạo (để hiển thị full token)
        /// </summary>
        public QrCodeViewModel? NewlyGeneratedQr { get; set; }

        public GenerateQrCodeViewModel GenerateForm { get; set; } = new();

        public EventQrListItemDtoPaginatedResultDto? Pagination { get; set; }

        public bool? IsActive { get; set; }
        public bool? ValidNow { get; set; }

        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public int TotalPages { get; set; } = 1;
        public bool HasPreviousPage => Pagination?.HasPreviousPage ?? PageNumber > 1;
        public bool HasNextPage => Pagination?.HasNextPage ?? PageNumber < TotalPages;
        public int TotalCount => Pagination?.TotalCount ?? QrCodes.Count;

        /// <summary>
        /// Helper properties cho thống kê
        /// </summary>
        public int TotalQrCodes => TotalCount;
        public int ActiveQrCodes => QrCodes.Count(q => q.IsActive && !q.IsExpired);
        public int ExpiredQrCodes => QrCodes.Count(q => q.IsExpired);
        public int DeactivatedQrCodes => QrCodes.Count(q => !q.IsActive && !q.IsExpired);

        public bool HasQrCodes => QrCodes.Any();
        public bool HasActiveQr => ActiveQrCodes > 0;
    }
}
