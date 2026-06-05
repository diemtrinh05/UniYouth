using System.ComponentModel.DataAnnotations;

using UniYouth.Admin.Models.DTOs.Attendance;

namespace UniYouth.Admin.Models.ViewModels.Attendance
{
    /// <summary>
    /// ViewModel chính cho trang danh sách điểm danh
    /// </summary>
    public class EventAttendanceListViewModel
    {
        public int EventId { get; set; }

        [Display(Name = "Tên Sự kiện")]
        public string EventName { get; set; } = string.Empty;

        [Display(Name = "Danh sách Điểm danh")]
        public List<EventAttendanceViewModel> Attendances { get; set; } = new();

        public EventAttendancesSummaryDto? Summary { get; set; }
        public AttendanceDetailDtoPaginatedResultDto? Pagination { get; set; }

        #region Filters/Sorting (swagger v2)

        public string? Q { get; set; }
        public bool? IsValid { get; set; }
        public string? Method { get; set; }
        public bool? FaceVerified { get; set; }
        public string? FaceVerificationStatus { get; set; }
        public string? RiskLevel { get; set; }
        public bool? SuspiciousOnly { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
        public string? SortBy { get; set; }
        public string? SortDir { get; set; }

        #endregion

        #region Pagination

        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public int TotalPages { get; set; } = 1;
        public bool HasPreviousPage => Pagination?.HasPreviousPage ?? PageNumber > 1;
        public bool HasNextPage => Pagination?.HasNextPage ?? PageNumber < TotalPages;

        #endregion

        /// <summary>
        /// Thống kê tổng quan
        /// </summary>
        public EventAttendanceStatsViewModel? Statistics { get; set; }

        /// <summary>
        /// Helper properties
        /// </summary>
        public int TotalAttendances => Summary?.TotalRecords ?? Pagination?.TotalCount ?? 0;
        public int ValidAttendances => Summary?.ValidCount ?? 0;
        public int InvalidAttendances => Summary?.InvalidCount ?? 0;
        public bool HasAttendances => Attendances.Any();
        public int SuspiciousAttendances => Attendances.Count(a => a.IsSuspicious);
        public int ReviewRequiredAttendances => Attendances.Count(a => a.NeedsManualReview);
        public int HighPriorityAttendances => Attendances.Count(a =>
            string.Equals(a.RiskLevel, "High", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(a.RiskLevel, "Critical", StringComparison.OrdinalIgnoreCase));
        public int FaceMismatchAttendances => Attendances.Count(a =>
            string.Equals(a.FaceVerificationStatus, "Mismatch", StringComparison.OrdinalIgnoreCase));
        public int FaceReviewAttendances => Attendances.Count(a =>
            string.Equals(a.FaceVerificationStatus, "Review", StringComparison.OrdinalIgnoreCase));
        public int TechnicalIssueAttendances => Attendances.Count(a =>
            string.Equals(a.FaceVerificationStatus, "TechnicalError", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(a.FaceVerificationStatus, "BlurryImage", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(a.FaceVerificationStatus, "NoFaceDetected", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(a.FaceVerificationStatus, "MultipleFacesDetected", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(a.FaceVerificationStatus, "InvalidPayload", StringComparison.OrdinalIgnoreCase));

        /// <summary>
        /// Tỷ lệ hợp lệ (%)
        /// </summary>
        public double ValidityRate => TotalAttendances > 0
            ? (ValidAttendances * 100.0 / TotalAttendances)
            : 0;
    }
}
