using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class User
{
    public virtual ICollection<SupportConversation> SupportConversationAssignedToUsers { get; set; } = new List<SupportConversation>();

    public virtual ICollection<SupportConversation> SupportConversationStudentUsers { get; set; } = new List<SupportConversation>();

    public virtual ICollection<SupportMessage> SupportMessages { get; set; } = new List<SupportMessage>();

    public virtual ICollection<SupportMessageRead> SupportMessageReads { get; set; } = new List<SupportMessageRead>();
}

