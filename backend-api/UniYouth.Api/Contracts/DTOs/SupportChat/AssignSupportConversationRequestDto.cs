using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.SupportChat
{
    public class AssignSupportConversationRequestDto
    {
        [Range(1, int.MaxValue, ErrorMessage = "Người phụ trách không hợp lệ")]
        public int? AssignedToUserId { get; set; }
    }
}

