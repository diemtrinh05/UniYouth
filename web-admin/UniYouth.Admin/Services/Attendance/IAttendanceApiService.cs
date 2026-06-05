using UniYouth.Admin.Models.DTOs.Attendance;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Attendance
{
    /// <summary>
    /// Interface cho AttendanceApiService
    /// Dùng để Dependency Injection
    /// </summary>
    public interface IAttendanceApiService
    {
        Task<ApiResult<EventAttendancesListResponseDto>> GetEventAttendancesAsync(
            int eventId,
            int pageNumber = 1,
            int pageSize = 10,
            string? q = null,
            bool? isValid = null,
            string? method = null,
            bool? faceVerified = null,
            string? faceVerificationStatus = null,
            string? riskLevel = null,
            bool? suspiciousOnly = null,
            DateTime? from = null,
            DateTime? to = null,
            string? sortBy = null,
            string? sortDir = null);
        Task<ApiResult<EventAttendanceStatsDto>> GetAttendanceStatsAsync(int eventId);
        Task<ApiResult<EventDetailDto>> GetEventDetailAsync(int eventId);
    }
}
