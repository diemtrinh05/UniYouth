using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace UniYouth.Api.Application.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
        private readonly ILogger<NotificationHub> _logger;

        public NotificationHub(ILogger<NotificationHub> logger)
        {
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            _logger.LogInformation(
                "SignalR connected: ConnectionId={ConnectionId}, UserIdentifier={UserIdentifier}",
                Context.ConnectionId,
                Context.UserIdentifier);

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            _logger.LogInformation(
                "SignalR disconnected: ConnectionId={ConnectionId}, UserIdentifier={UserIdentifier}, Error={Error}",
                Context.ConnectionId,
                Context.UserIdentifier,
                exception?.Message);

            await base.OnDisconnectedAsync(exception);
        }
    }
}
