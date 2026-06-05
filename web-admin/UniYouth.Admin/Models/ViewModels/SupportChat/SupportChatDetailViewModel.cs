using UniYouth.Admin.Models.DTOs.SupportChat;

namespace UniYouth.Admin.Models.ViewModels.SupportChat
{
    public class SupportChatDetailViewModel
    {
        public SupportConversationDto Conversation { get; set; } = new();
        public SupportMessageDtoPaginatedResultDto MessagesPage { get; set; } = new()
        {
            Items = new List<SupportMessageDto>(),
            PageNumber = 1,
            PageSize = 100,
            TotalPages = 1
        };

        public SendSupportMessageRequestDto SendMessage { get; set; } = new();
        public AssignSupportConversationRequestDto Assign { get; set; } = new();
        public UpdateSupportConversationStatusRequestDto UpdateStatus { get; set; } = new();

        public List<SupportMessageDto> Messages => MessagesPage.Items ?? new List<SupportMessageDto>();
    }
}

