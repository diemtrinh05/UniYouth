namespace UniYouth.Admin.Models.DTOs.SupportChat
{
    public class SupportMessageDto
    {
        public int MessageId { get; set; }
        public int ConversationId { get; set; }
        public int SenderUserId { get; set; }
        public string SenderFullName { get; set; } = string.Empty;
        public string SenderCode { get; set; } = string.Empty;
        public byte MessageType { get; set; }
        public string Content { get; set; } = string.Empty;
        public string? AttachmentUrl { get; set; }
        public bool IsMine { get; set; }
        public DateTime CreatedDate { get; set; }
    }
}

