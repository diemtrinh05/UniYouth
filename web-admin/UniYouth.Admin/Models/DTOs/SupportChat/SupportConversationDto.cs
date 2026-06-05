namespace UniYouth.Admin.Models.DTOs.SupportChat
{
    public class SupportConversationDto
    {
        public int ConversationId { get; set; }
        public int StudentUserId { get; set; }
        public string StudentCode { get; set; } = string.Empty;
        public string StudentFullName { get; set; } = string.Empty;
        public int? AssignedToUserId { get; set; }
        public string? AssignedToFullName { get; set; }
        public string Subject { get; set; } = string.Empty;
        public byte Status { get; set; }
        public string StatusName { get; set; } = string.Empty;
        public byte Priority { get; set; }
        public string PriorityName { get; set; } = string.Empty;
        public string? LastMessagePreview { get; set; }
        public int UnreadCount { get; set; }
        public DateTime? LastMessageAt { get; set; }
        public DateTime? ClosedAt { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime UpdatedDate { get; set; }
    }
}

