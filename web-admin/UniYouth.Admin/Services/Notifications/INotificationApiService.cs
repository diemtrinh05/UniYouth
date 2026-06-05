using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Notifications
{
    /// <summary>
    /// Notification API contract cho Web Admin.
    /// Source of truth: swagger_v4.json.
    /// </summary>
    public interface INotificationApiService
    {
        /// <summary>
        /// GET /api/notifications?pageNumber={pageNumber}&pageSize={pageSize}
        /// </summary>
        Task<ApiResult<ApiResponseDto>> GetNotificationsAsync(
            int pageNumber = 1,
            int pageSize = 20);

        /// <summary>
        /// GET /api/notifications/unread-count
        /// </summary>
        Task<ApiResult<ApiResponseDto>> GetUnreadCountAsync();

        /// <summary>
        /// PUT /api/notifications/{id}/read
        /// </summary>
        Task<ApiResult<ApiResponseDto>> MarkAsReadAsync(int id);

        /// <summary>
        /// PUT /api/notifications/read-all
        /// </summary>
        Task<ApiResult<ApiResponseDto>> MarkAllAsReadAsync();
    }
}
