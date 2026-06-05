using System;

namespace UniYouth.Api.Domain.Entities;

public partial class NotificationDeliveryLog
{
    public int DeliveryLogID { get; set; }

    public int OutboxID { get; set; }

    public int NotificationID { get; set; }

    public int UserID { get; set; }

    public byte Channel { get; set; }

    public int AttemptNumber { get; set; }

    public bool IsSuccess { get; set; }

    public string? ErrorMessage { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual Notification Notification { get; set; } = null!;

    public virtual NotificationOutbox Outbox { get; set; } = null!;
}
