using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class NotificationOutbox
{
    public int OutboxID { get; set; }

    public int NotificationID { get; set; }

    public int UserID { get; set; }

    public byte Channel { get; set; }

    public byte Status { get; set; }

    public int AttemptCount { get; set; }

    public int MaxAttempts { get; set; }

    public DateTime? NextAttemptAt { get; set; }

    public DateTime? LastAttemptAt { get; set; }

    public DateTime? ProcessedAt { get; set; }

    public string? LastError { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual Notification Notification { get; set; } = null!;

    public virtual ICollection<NotificationDeliveryLog> NotificationDeliveryLogs { get; set; } = new List<NotificationDeliveryLog>();
}
