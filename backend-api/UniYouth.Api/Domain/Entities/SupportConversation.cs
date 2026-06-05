using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class SupportConversation
{
    public int ConversationID { get; set; }

    public int StudentUserID { get; set; }

    public int? AssignedToUserID { get; set; }

    public string Subject { get; set; } = null!;

    public byte Status { get; set; }

    public byte Priority { get; set; }

    public DateTime? LastMessageAt { get; set; }

    public DateTime? ClosedAt { get; set; }

    public DateTime CreatedDate { get; set; }

    public DateTime UpdatedDate { get; set; }

    public virtual User StudentUser { get; set; } = null!;

    public virtual User? AssignedToUser { get; set; }

    public virtual ICollection<SupportMessage> SupportMessages { get; set; } = new List<SupportMessage>();
}

