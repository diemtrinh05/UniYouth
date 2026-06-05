using Microsoft.AspNetCore.SignalR;
using UniYouth.Api.Application.Hubs;
using UniYouth.Api.Contracts.DTOs.SupportChat;

namespace UniYouth.Api.Application.Services
{
    public interface ISupportChatRealtimeDispatcher
    {
        Task DispatchConversationCreatedAsync(SupportConversationDto conversation, CancellationToken cancellationToken = default);
        Task DispatchConversationUpdatedAsync(SupportConversationDto conversation, CancellationToken cancellationToken = default);
        Task DispatchMessageCreatedAsync(SupportMessageDto message, IReadOnlyCollection<int> recipientUserIds, CancellationToken cancellationToken = default);
        Task DispatchMessagesReadAsync(int conversationId, int userId, int readCount, CancellationToken cancellationToken = default);
    }

    public class SupportChatRealtimeDispatcher : ISupportChatRealtimeDispatcher
    {
        private readonly IHubContext<SupportChatHub> _hubContext;
        private readonly ILogger<SupportChatRealtimeDispatcher> _logger;

        public SupportChatRealtimeDispatcher(
            IHubContext<SupportChatHub> hubContext,
            ILogger<SupportChatRealtimeDispatcher> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public Task DispatchConversationCreatedAsync(SupportConversationDto conversation, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("Dispatch support_conversation_created: ConversationID={ConversationId}", conversation.ConversationId);
            return _hubContext.Clients.Group(SupportChatHubGroups.Staff).SendAsync(
                "support_conversation_created",
                conversation,
                cancellationToken);
        }

        public async Task DispatchConversationUpdatedAsync(SupportConversationDto conversation, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("Dispatch support_conversation_updated: ConversationID={ConversationId}", conversation.ConversationId);

            await _hubContext.Clients.Group(SupportChatHubGroups.Conversation(conversation.ConversationId)).SendAsync(
                "support_conversation_updated",
                conversation,
                cancellationToken);

            await _hubContext.Clients.Group(SupportChatHubGroups.Staff).SendAsync(
                "support_conversation_updated",
                conversation,
                cancellationToken);

            await _hubContext.Clients.Group(SupportChatHubGroups.User(conversation.StudentUserId)).SendAsync(
                "support_conversation_updated",
                conversation,
                cancellationToken);
        }

        public async Task DispatchMessageCreatedAsync(
            SupportMessageDto message,
            IReadOnlyCollection<int> recipientUserIds,
            CancellationToken cancellationToken = default)
        {
            _logger.LogDebug(
                "Dispatch support_message_created: ConversationID={ConversationId}, MessageID={MessageId}",
                message.ConversationId,
                message.MessageId);

            await _hubContext.Clients.Group(SupportChatHubGroups.Conversation(message.ConversationId)).SendAsync(
                "support_message_created",
                message,
                cancellationToken);

            foreach (var recipientUserId in recipientUserIds.Distinct())
            {
                await _hubContext.Clients.Group(SupportChatHubGroups.User(recipientUserId)).SendAsync(
                    "support_message_created",
                    message,
                    cancellationToken);
            }

            await _hubContext.Clients.Group(SupportChatHubGroups.Staff).SendAsync(
                "support_message_created",
                message,
                cancellationToken);
        }

        public async Task DispatchMessagesReadAsync(
            int conversationId,
            int userId,
            int readCount,
            CancellationToken cancellationToken = default)
        {
            var payload = new
            {
                conversationId,
                userId,
                readCount,
                readAt = DateTime.Now
            };

            await _hubContext.Clients.Group(SupportChatHubGroups.Conversation(conversationId)).SendAsync(
                "support_messages_read",
                payload,
                cancellationToken);
        }
    }
}

