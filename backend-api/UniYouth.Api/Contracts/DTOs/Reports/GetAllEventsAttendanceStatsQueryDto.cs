namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class GetAllEventsAttendanceStatsQueryDto
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;

        public string? Q { get; set; }

        /// <summary>
        /// Trạng thái sự kiện (int) theo enum EventStatus trong hệ thống.
        /// </summary>
        public int? Status { get; set; }

        /// <summary>
        /// Lọc theo khoảng StartTime (từ ngày/giờ).
        /// </summary>
        public DateTime? From { get; set; }

        /// <summary>
        /// Lọc theo khoảng StartTime (đến ngày/giờ).
        /// </summary>
        public DateTime? To { get; set; }

        /// <summary>
        /// Whitelist: startTime | attendanceRate | totalRegistrations | validAttendances | invalidAttendances | notCheckedIn | eventName
        /// </summary>
        public string? SortBy { get; set; }

        /// <summary>
        /// asc | desc
        /// </summary>
        public string? SortDir { get; set; }
    }
}

