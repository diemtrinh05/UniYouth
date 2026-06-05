namespace UniYouth.Admin.Models.ViewModels.Reports
{
    /// <summary>
    /// ViewModel cho trang danh sách báo cáo
    /// Chứa danh sách các báo cáo và các filter
    /// </summary>
    public class EventReportListViewModel
    {
        public UniYouth.Admin.Models.DTOs.Reports.AllEventsAttendanceStatsSummaryDto? Summary { get; set; }
        public UniYouth.Admin.Models.DTOs.Reports.PaginationMetaDto? Pagination { get; set; }

        public bool HasSummary => Summary != null;

        /// <summary>
        /// Danh sách các báo cáo sự kiện
        /// </summary>
        public List<EventReportListItemViewModel> EventReports { get; set; } = new();

        /// <summary>
        /// Danh sách báo cáo hiển thị theo trang (client-side pagination)
        /// </summary>
        public List<EventReportListItemViewModel> PagedEventReports { get; set; } = new();

        /// <summary>
        /// Từ khóa tìm kiếm
        /// </summary>
        public string? SearchTerm { get; set; }

        /// <summary>
        /// Lọc từ ngày
        /// </summary>
        public DateTime? StartDate { get; set; }

        /// <summary>
        /// Lọc đến ngày
        /// </summary>
        public DateTime? EndDate { get; set; }

        public int? Status { get; set; }
        public string? SortBy { get; set; }
        public string? SortDir { get; set; }

        #region Pagination

        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public int TotalPages { get; set; } = 1;
        public bool HasPreviousPage => Pagination?.HasPreviousPage ?? PageNumber > 1;
        public bool HasNextPage => Pagination?.HasNextPage ?? PageNumber < TotalPages;

        #endregion

        #region Computed Properties

        /// <summary>
        /// Tổng số sự kiện
        /// </summary>
        public int TotalEvents => Summary?.TotalEvents ?? (Pagination?.TotalCount ?? 0);

        /// <summary>
        /// Tổng số đăng ký
        /// </summary>
        public int TotalRegistrations => Summary?.TotalRegistrations ?? 0;

        /// <summary>
        /// Tổng số điểm danh hợp lệ
        /// </summary>
        public int TotalValidAttendances => Summary?.TotalValidAttendances ?? 0;

        /// <summary>
        /// Tổng số điểm danh không hợp lệ
        /// </summary>
        public int TotalInvalidAttendances => Summary?.TotalInvalidAttendances ?? 0;

        /// <summary>
        /// Tỷ lệ tham gia trung bình
        /// </summary>
        public double AverageAttendanceRate
        {
            get
            {
                return Summary?.AverageAttendanceRate ?? 0;
            }
        }

        /// <summary>
        /// Format tỷ lệ tham gia trung bình
        /// </summary>
        public string AverageAttendanceRateFormatted => $"{AverageAttendanceRate:F1}%";

        /// <summary>
        /// Kiểm tra có đang áp dụng filter không
        /// </summary>
        public bool HasFilters =>
            !string.IsNullOrWhiteSpace(SearchTerm) ||
            StartDate.HasValue ||
            EndDate.HasValue ||
            Status.HasValue ||
            !string.IsNullOrWhiteSpace(SortBy) ||
            !string.IsNullOrWhiteSpace(SortDir);

        #endregion

        #region Methods

        /// <summary>
        /// Áp dụng các filter client-side
        /// Lọc danh sách EventReports theo SearchTerm, StartDate, EndDate
        /// </summary>
        public void ApplyFilters()
        {
            var filtered = EventReports.AsEnumerable();

            // Lọc theo từ khóa tìm kiếm
            if (!string.IsNullOrWhiteSpace(SearchTerm))
            {
                filtered = filtered.Where(e =>
                    e.EventName.Contains(SearchTerm, StringComparison.OrdinalIgnoreCase));
            }

            // Lọc theo ngày bắt đầu
            if (StartDate.HasValue)
            {
                filtered = filtered.Where(e => e.StartTime.Date >= StartDate.Value.Date);
            }

            // Lọc theo ngày kết thúc
            if (EndDate.HasValue)
            {
                filtered = filtered.Where(e => e.StartTime.Date <= EndDate.Value.Date);
            }

            // Sắp xếp theo thời gian bắt đầu (mới nhất trước)
            filtered = filtered.OrderByDescending(e => e.StartTime);

            EventReports = filtered.ToList();
        }

        /// <summary>
        /// Áp dụng phân trang client-side trên danh sách đã filter
        /// </summary>
        public void ApplyPagination(int pageNumber, int pageSize)
        {
            PageSize = pageSize > 0 ? pageSize : 10;

            var totalCount = EventReports.Count;
            TotalPages = Math.Max(1, (int)Math.Ceiling(totalCount / (double)PageSize));

            PageNumber = pageNumber <= 0 ? 1 : pageNumber;
            if (PageNumber > TotalPages)
            {
                PageNumber = TotalPages;
            }

            PagedEventReports = EventReports
                .Skip((PageNumber - 1) * PageSize)
                .Take(PageSize)
                .ToList();
        }

        #endregion
    }
}
