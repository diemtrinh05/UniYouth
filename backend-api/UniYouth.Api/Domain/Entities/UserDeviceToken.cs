using System;

namespace UniYouth.Api.Domain.Entities;

public partial class UserDeviceToken
{
    public int UserDeviceTokenID { get; set; }

    public int UserID { get; set; }

    public string Platform { get; set; } = null!;

    public string Token { get; set; } = null!;

    public string? DeviceId { get; set; }

    public bool IsActive { get; set; }

    public DateTime LastSeenAt { get; set; }

    public DateTime CreatedDate { get; set; }

    public DateTime UpdatedDate { get; set; }

    public virtual User User { get; set; } = null!;
}

