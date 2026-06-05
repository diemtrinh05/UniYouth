using System;

namespace UniYouth.Api.Domain.Entities;

public partial class PasswordResetSession
{
    public int ResetSessionID { get; set; }

    public int UserID { get; set; }

    public int OtpID { get; set; }

    public string SessionTokenHash { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }

    public bool IsUsed { get; set; }

    public DateTime CreatedDate { get; set; }

    public DateTime? UsedAt { get; set; }

    public virtual PasswordResetOtp Otp { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
