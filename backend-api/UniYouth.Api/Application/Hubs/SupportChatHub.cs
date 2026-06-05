using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using UniYouth.Api.Shared.Constants;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Application.Hubs
{
    [Authorize]
    public class SupportChatHub : Hub
    {
        private readonly ILogger<SupportChatHub> _logger;

        public SupportChatHub(ILogger<SupportChatHub> logger)
        {
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.GetUserId();
            if (userId.HasValue)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, SupportChatHubGroups.User(userId.Value));
            }

            if (Context.User?.IsInRole(RoleNames.Admin) == true || Context.User?.IsInRole(RoleNames.CanBo) == true)
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, SupportChatHubGroups.Staff);
            }

            _logger.LogInformation(
                "Support chat connected: ConnectionId={ConnectionId}, UserID={UserId}",
                Context.ConnectionId,
                userId);

            await base.OnConnectedAsync();
        }

        public async Task JoinConversation(int conversationId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, SupportChatHubGroups.Conversation(conversationId));
        }

        public async Task LeaveConversation(int conversationId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, SupportChatHubGroups.Conversation(conversationId));
        }
    }

    public static class SupportChatHubGroups
    {
        public const string Staff = "support:staff";

        public static string User(int userId) => $"user:{userId}";

        public static string Conversation(int conversationId) => $"support:conversation:{conversationId}";
    }
}

