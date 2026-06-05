using System;

namespace UniYouth.Api.Domain.Entities;

public partial class SupportMessageRead
{
    public int ReadID { get; set; }

    public int MessageID { get; set; }

    public int UserID { get; set; }

    public DateTime ReadAt { get; set; }

    public virtual SupportMessage Message { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}

