using UniYouth.Admin.Models.DTOs.SupportChat;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.SupportChat
{
    public interface ISupportChatApiService
    {
        Task<ApiResult<SupportConversationDtoPaginatedResultDto>> GetConversationsAsync(
            int pageNumber = 1,
            int pageSize = 20,
            byte? status = null,
            byte? priority = null,
            int? assignedToUserId = null,
            string? search = null);

        Task<ApiResult<SupportConversationDto>> GetConversationAsync(int conversationId);

        Task<ApiResult<SupportMessageDtoPaginatedResultDto>> GetMessagesAsync(
            int conversationId,
            int pageNumber = 1,
            int pageSize = 100);

        Task<ApiResult<SupportMessageDto>> SendMessageAsync(int conversationId, SendSupportMessageRequestDto request);

        Task<ApiResult<SupportMessageDto>> SendAttachmentAsync(int conversationId, string? content, IFormFile file);

        Task<ApiResult<SupportConversationDto>> AssignConversationAsync(int conversationId, AssignSupportConversationRequestDto request);

        Task<ApiResult<SupportConversationDto>> UpdateStatusAsync(int conversationId, UpdateSupportConversationStatusRequestDto request);

        Task<ApiResult<string?>> MarkAsReadAsync(int conversationId);
    }
}
