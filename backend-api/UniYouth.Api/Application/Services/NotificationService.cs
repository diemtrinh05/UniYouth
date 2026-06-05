using UniYouth.Api.Application.Services.NotificationsSupport;
using UniYouth.Api.Contracts.DTOs.Notifications;

namespace UniYouth.Api.Application.Services
{
    public interface INotificationService
    {
        Task<NotificationListResponseDto> GetUserNotificationsAsync(int userId, int pageNumber = 1, int pageSize = 20);
        Task<bool> MarkAsReadAsync(int notificationId, int userId);
        Task<int> MarkAllAsReadAsync(int userId);
        Task<int> CreateNotificationAsync(CreateNotificationDto dto);
        Task CreateEventRegistrationNotificationAsync(int userId, int eventId, string eventName);
        Task CreateEventCancelRegistrationNotificationAsync(int userId, int eventId, string eventName, string? reason);
        Task CreateAttendanceNotificationAsync(int userId, int eventId, string eventName, bool isValid, int? pointsEarned = null, string? invalidReason = null);
        Task CreateEventUpdateNotificationsAsync(int eventId, string eventName, string updateMessage);
        Task CreateEventCancellationNotificationsAsync(int eventId, string eventName, string? reason);
        Task CreateEventCapacityFullAlertAsync(int eventId, string eventName, int currentParticipants, int maxParticipants);
        Task CreateQrScanLimitReachedAlertAsync(int eventId, string eventName, int qrId, int currentScans, int scanLimit);
        Task CreateQrDeactivatedAlertAsync(int eventId, string eventName, int qrId, int deactivatedByUserId);
        Task CreateActorEventActionConfirmationAsync(int actorUserId, int eventId, string eventName, string actionName, string? actionDetail = null, long? operationStamp = null);
        Task CreateActorEventQrActionConfirmationAsync(int actorUserId, int eventId, string eventName, int qrId, string actionName, string? actionDetail = null, long? operationStamp = null);
        Task CreateActorEventPointActionConfirmationAsync(int actorUserId, int eventId, string eventName, string roleType, string actionName, string? actionDetail = null, long? operationStamp = null);
        Task CreateSuspiciousAttendanceAlertAsync(int attendanceId, int eventId, string eventName, int attendeeUserId, int? riskScore, string? riskLevel, string? faceVerificationStatus);
        Task<int> GetUnreadCountAsync(int userId);
        Task<int> DeleteExpiredNotificationsAsync();
        Task<int> ArchiveOldNotificationsAsync(int batchSize = 500, int retentionDays = 90);
    }

    public class NotificationService : INotificationService
    {
        private readonly NotificationInboxService _inboxService;
        private readonly NotificationComposerService _composerService;
        private readonly NotificationMaintenanceService _maintenanceService;

        public NotificationService(UniYouth.Api.Infrastructure.Data.UniYouthDbContext context, ILogger<NotificationService> logger)
        {
            var routingService = new NotificationRoutingService(context);
            _inboxService = new NotificationInboxService(context, logger);
            _composerService = new NotificationComposerService(context, logger, routingService);
            _maintenanceService = new NotificationMaintenanceService(context, logger);
        }

        public Task<NotificationListResponseDto> GetUserNotificationsAsync(int userId, int pageNumber = 1, int pageSize = 20)
            => _inboxService.GetUserNotificationsAsync(userId, pageNumber, pageSize);

        public Task<bool> MarkAsReadAsync(int notificationId, int userId)
            => _inboxService.MarkAsReadAsync(notificationId, userId);

        public Task<int> MarkAllAsReadAsync(int userId)
            => _inboxService.MarkAllAsReadAsync(userId);

        public Task<int> CreateNotificationAsync(CreateNotificationDto dto)
            => _composerService.CreateNotificationAsync(dto);

        public Task CreateEventRegistrationNotificationAsync(int userId, int eventId, string eventName)
            => _composerService.CreateEventRegistrationNotificationAsync(userId, eventId, eventName);

        public Task CreateEventCancelRegistrationNotificationAsync(int userId, int eventId, string eventName, string? reason)
            => _composerService.CreateEventCancelRegistrationNotificationAsync(userId, eventId, eventName, reason);

        public Task CreateAttendanceNotificationAsync(int userId, int eventId, string eventName, bool isValid, int? pointsEarned = null, string? invalidReason = null)
            => _composerService.CreateAttendanceNotificationAsync(userId, eventId, eventName, isValid, pointsEarned, invalidReason);

        public Task CreateEventUpdateNotificationsAsync(int eventId, string eventName, string updateMessage)
            => _composerService.CreateEventUpdateNotificationsAsync(eventId, eventName, updateMessage);

        public Task CreateEventCancellationNotificationsAsync(int eventId, string eventName, string? reason)
            => _composerService.CreateEventCancellationNotificationsAsync(eventId, eventName, reason);

        public Task CreateEventCapacityFullAlertAsync(int eventId, string eventName, int currentParticipants, int maxParticipants)
            => _composerService.CreateEventCapacityFullAlertAsync(eventId, eventName, currentParticipants, maxParticipants);

        public Task CreateQrScanLimitReachedAlertAsync(int eventId, string eventName, int qrId, int currentScans, int scanLimit)
            => _composerService.CreateQrScanLimitReachedAlertAsync(eventId, eventName, qrId, currentScans, scanLimit);

        public Task CreateQrDeactivatedAlertAsync(int eventId, string eventName, int qrId, int deactivatedByUserId)
            => _composerService.CreateQrDeactivatedAlertAsync(eventId, eventName, qrId, deactivatedByUserId);

        public Task CreateActorEventActionConfirmationAsync(int actorUserId, int eventId, string eventName, string actionName, string? actionDetail = null, long? operationStamp = null)
            => _composerService.CreateActorEventActionConfirmationAsync(actorUserId, eventId, eventName, actionName, actionDetail, operationStamp);

        public Task CreateActorEventQrActionConfirmationAsync(int actorUserId, int eventId, string eventName, int qrId, string actionName, string? actionDetail = null, long? operationStamp = null)
            => _composerService.CreateActorEventQrActionConfirmationAsync(actorUserId, eventId, eventName, qrId, actionName, actionDetail, operationStamp);

        public Task CreateActorEventPointActionConfirmationAsync(int actorUserId, int eventId, string eventName, string roleType, string actionName, string? actionDetail = null, long? operationStamp = null)
            => _composerService.CreateActorEventPointActionConfirmationAsync(actorUserId, eventId, eventName, roleType, actionName, actionDetail, operationStamp);

        public Task CreateSuspiciousAttendanceAlertAsync(int attendanceId, int eventId, string eventName, int attendeeUserId, int? riskScore, string? riskLevel, string? faceVerificationStatus)
            => _composerService.CreateSuspiciousAttendanceAlertAsync(attendanceId, eventId, eventName, attendeeUserId, riskScore, riskLevel, faceVerificationStatus);

        public Task<int> GetUnreadCountAsync(int userId)
            => _inboxService.GetUnreadCountAsync(userId);

        public Task<int> DeleteExpiredNotificationsAsync()
            => _maintenanceService.DeleteExpiredNotificationsAsync();

        public Task<int> ArchiveOldNotificationsAsync(int batchSize = 500, int retentionDays = 90)
            => _maintenanceService.ArchiveOldNotificationsAsync(batchSize, retentionDays);
    }
}
