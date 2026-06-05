using UniYouth.Admin.Models.DTOs.Reports;

namespace UniYouth.Admin.Services.Reports
{
    /// <summary>
    /// Interface cho ReportsService
    /// Dùng để Dependency Injection
    /// </summary>
    public interface IReportsApiService
    {
        /// <summary>
        /// Lấy danh sách thống kê điểm danh của tất cả sự kiện
        /// API: GET /api/events/all/attendance-stats
        /// </summary>
        Task<AllEventsAttendanceStatsResponseDto?> GetAllEventStatsAsync(
            int pageNumber = 1,
            int pageSize = 10,
            string? q = null,
            int? status = null,
            DateTime? from = null,
            DateTime? to = null,
            string? sortBy = null,
            string? sortDir = null);

        /// <summary>
        /// Lấy thống kê chi tiết điểm danh của một sự kiện
        /// API: GET /api/events/{eventId}/attendance-stats
        /// </summary>
        Task<EventAttendanceStatsDto?> GetEventAttendanceStatsAsync(int eventId);

        Task<BiometricTelemetryListResponseDto?> GetBiometricTelemetryAsync(
            int pageNumber = 1,
            int pageSize = 20,
            string? q = null,
            int? eventId = null,
            DateTime? from = null,
            DateTime? to = null,
            string? faceStatus = null,
            string? livenessStatus = null,
            bool? onlyInvalid = null);
    }
}
