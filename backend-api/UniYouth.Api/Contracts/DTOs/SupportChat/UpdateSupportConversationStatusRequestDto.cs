using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.SupportChat
{
    public class UpdateSupportConversationStatusRequestDto
    {
        [Range(1, 3, ErrorMessage = "Trạng thái chỉ hợp lệ từ 1 đến 3")]
        public byte Status { get; set; }
    }
}

