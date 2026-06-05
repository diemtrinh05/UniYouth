using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class AuditLog
{
    public int AuditID { get; set; }

    public int? UserID { get; set; }

    public string Action { get; set; } = null!;

    public string? TableName { get; set; }

    public int? RecordID { get; set; }

    public string? OldValue { get; set; }

    public string? NewValue { get; set; }

    public string? IPAddress { get; set; }

    public string? UserAgent { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual User? User { get; set; }
}
