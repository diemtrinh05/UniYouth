using UniYouth.Admin.Models.DTOs.SupportChat;

namespace UniYouth.Admin.Models.ViewModels.SupportChat
{
    public class SupportChatIndexViewModel
    {
        public SupportConversationDtoPaginatedResultDto ConversationsPage { get; set; } = new()
        {
            Items = new List<SupportConversationDto>(),
            PageNumber = 1,
            PageSize = 20,
            TotalPages = 1
        };

        public byte? Status { get; set; }
        public byte? Priority { get; set; }
        public int? AssignedToUserId { get; set; }
        public string? Search { get; set; }

        public int PageNumber => ConversationsPage.PageNumber <= 0 ? 1 : ConversationsPage.PageNumber;
        public int PageSize => ConversationsPage.PageSize <= 0 ? 20 : ConversationsPage.PageSize;
        public int TotalPages => ConversationsPage.TotalPages <= 0 ? 1 : ConversationsPage.TotalPages;
        public int TotalCount => ConversationsPage.TotalCount;
        public List<SupportConversationDto> Conversations => ConversationsPage.Items ?? new List<SupportConversationDto>();
    }
}

