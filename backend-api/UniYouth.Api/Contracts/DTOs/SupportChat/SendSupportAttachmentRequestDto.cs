using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace UniYouth.Api.Contracts.DTOs.SupportChat
{
    public class SendSupportAttachmentRequestDto
    {
        [StringLength(1000, ErrorMessage = "Nội dung ghi chú không được vượt quá 1000 ký tự")]
        public string? Content { get; set; }

        [Required(ErrorMessage = "File minh chứng là bắt buộc")]
        public IFormFile File { get; set; } = null!;
    }
}
