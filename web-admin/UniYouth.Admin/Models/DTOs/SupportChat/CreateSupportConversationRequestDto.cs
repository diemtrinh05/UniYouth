using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.DTOs.SupportChat
{
    public class CreateSupportConversationRequestDto
    {
        [Required(ErrorMessage = "Tiêu đề là bắt buộc")]
        [StringLength(255, MinimumLength = 3, ErrorMessage = "Tiêu đề phải từ 3 đến 255 ký tự")]
        public string Subject { get; set; } = string.Empty;

        [Required(ErrorMessage = "Nội dung là bắt buộc")]
        [StringLength(4000, ErrorMessage = "Nội dung không được vượt quá 4000 ký tự")]
        public string Content { get; set; } = string.Empty;

        [Range(1, 3, ErrorMessage = "Mức ưu tiên không hợp lệ")]
        public byte Priority { get; set; } = 1;
    }
}

