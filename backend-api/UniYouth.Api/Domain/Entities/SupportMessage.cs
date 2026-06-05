using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class SupportMessage
{
    public int MessageID { get; set; }

    public int ConversationID { get; set; }

    public int SenderUserID { get; set; }

    public byte MessageType { get; set; }

    public string Content { get; set; } = null!;

    public string? AttachmentUrl { get; set; }

    public bool IsDeleted { get; set; }

    public DateTime CreatedDate { get; set; }

    public virtual SupportConversation Conversation { get; set; } = null!;

    public virtual User SenderUser { get; set; } = null!;

    public virtual ICollection<SupportMessageRead> SupportMessageReads { get; set; } = new List<SupportMessageRead>();
}

