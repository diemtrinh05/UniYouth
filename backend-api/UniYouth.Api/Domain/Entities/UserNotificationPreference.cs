using System;

namespace UniYouth.Api.Domain.Entities;

public partial class UserNotificationPreference
{
    public int PreferenceID { get; set; }

    public int UserID { get; set; }

    public int NotificationTypeID { get; set; }

    public bool IsInAppEnabled { get; set; }

    public bool IsRealtimeEnabled { get; set; }

    public bool IsPushEnabled { get; set; }

    public bool IsMuted { get; set; }

    public short? QuietHoursStartMinute { get; set; }

    public short? QuietHoursEndMinute { get; set; }

    public DateTime CreatedDate { get; set; }

    public DateTime UpdatedDate { get; set; }

    public virtual NotificationType NotificationType { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
