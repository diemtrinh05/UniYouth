using Microsoft.AspNetCore.SignalR;
using UniYouth.Api.Application.Hubs;

namespace UniYouth.Api.Application.Services
{
    public interface INotificationRealtimeDispatcher
    {
        Task DispatchCreatedAsync(NotificationRealtimePayload payload, CancellationToken cancellationToken = default);
        Task DispatchReadAsync(NotificationReadRealtimePayload payload, CancellationToken cancellationToken = default);
        Task DispatchReadAllAsync(NotificationReadAllRealtimePayload payload, CancellationToken cancellationToken = default);
    }

    public sealed record NotificationRealtimePayload(
        int NotificationId,
        int UserId,
        int? EventId,
        string Title,
        string Content,
        string Type,
        byte Priority,
        string? ActionUrl,
        DateTime CreatedDate,
        string? Audience,
        string? TargetRole,
        int UnreadCount);

    public sealed record NotificationReadRealtimePayload(
        int NotificationId,
        int UserId,
        DateTime ReadDate,
        int UnreadCount);

    public sealed record NotificationReadAllRealtimePayload(
        int UserId,
        int MarkedCount,
        DateTime ReadDate,
        int UnreadCount);

    public sealed class NotificationRealtimeDispatcher : INotificationRealtimeDispatcher
    {
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<NotificationRealtimeDispatcher> _logger;

        public NotificationRealtimeDispatcher(
            IHubContext<NotificationHub> hubContext,
            ILogger<NotificationRealtimeDispatcher> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task DispatchCreatedAsync(
            NotificationRealtimePayload payload,
            CancellationToken cancellationToken = default)
        {
            var userChannel = payload.UserId.ToString();

            await _hubContext.Clients.User(userChannel).SendAsync(
                "notification_created",
                payload,
                cancellationToken);

            _logger.LogDebug(
                "Dispatched SignalR notification_created to User={UserId}, NotificationId={NotificationId}",
                payload.UserId,
                payload.NotificationId);
        }

        public async Task DispatchReadAsync(
            NotificationReadRealtimePayload payload,
            CancellationToken cancellationToken = default)
        {
            var userChannel = payload.UserId.ToString();

            await _hubContext.Clients.User(userChannel).SendAsync(
                "notification_read",
                payload,
                cancellationToken);

            _logger.LogDebug(
                "Dispatched SignalR notification_read to User={UserId}, NotificationId={NotificationId}",
                payload.UserId,
                payload.NotificationId);
        }

        public async Task DispatchReadAllAsync(
            NotificationReadAllRealtimePayload payload,
            CancellationToken cancellationToken = default)
        {
            var userChannel = payload.UserId.ToString();

            await _hubContext.Clients.User(userChannel).SendAsync(
                "notification_read_all",
                payload,
                cancellationToken);

            _logger.LogDebug(
                "Dispatched SignalR notification_read_all to User={UserId}, MarkedCount={MarkedCount}",
                payload.UserId,
                payload.MarkedCount);
        }
    }
}
