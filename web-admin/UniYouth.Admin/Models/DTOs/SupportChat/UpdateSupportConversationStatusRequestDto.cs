using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.DTOs.SupportChat
{
    public class UpdateSupportConversationStatusRequestDto
    {
        [Range(1, 3, ErrorMessage = "Trạng thái không hợp lệ")]
        public byte Status { get; set; }
    }
}

