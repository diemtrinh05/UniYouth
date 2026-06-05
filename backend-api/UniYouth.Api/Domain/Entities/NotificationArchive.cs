using System;

namespace UniYouth.Api.Domain.Entities;

public partial class NotificationArchive
{
    public int NotificationID { get; set; }

    public int UserID { get; set; }

    public int? EventID { get; set; }

    public string Title { get; set; } = null!;

    public string Content { get; set; } = null!;

    public int NotificationTypeID { get; set; }

    public byte? Priority { get; set; }

    public bool? IsRead { get; set; }

    public DateTime? ReadDate { get; set; }

    public string? ActionUrl { get; set; }

    public string? DedupKey { get; set; }

    public string? Audience { get; set; }

    public string? TargetRole { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? ExpiryDate { get; set; }

    public DateTime ArchivedDate { get; set; }

    public string? ArchiveReason { get; set; }
}
