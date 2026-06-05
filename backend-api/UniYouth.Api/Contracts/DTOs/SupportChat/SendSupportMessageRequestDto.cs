using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.SupportChat
{
    public class SendSupportMessageRequestDto
    {
        [Required(ErrorMessage = "Nội dung tin nhắn là bắt buộc")]
        [StringLength(4000, MinimumLength = 1, ErrorMessage = "Nội dung tin nhắn không được vượt quá 4000 ký tự")]
        public string Content { get; set; } = string.Empty;
    }
}

