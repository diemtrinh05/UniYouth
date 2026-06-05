using System;

namespace UniYouth.Api.Domain.Entities;

public partial class PasswordResetOtp
{
    public int OtpID { get; set; }

    public int UserID { get; set; }

    public string OtpHash { get; set; } = null!;

    public string Purpose { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }

    public int AttemptCount { get; set; }

    public int MaxAttempts { get; set; }

    public int ResendCount { get; set; }

    public int MaxResends { get; set; }

    public bool IsUsed { get; set; }

    public DateTime? VerifiedAt { get; set; }

    public DateTime? UsedAt { get; set; }

    public DateTime? RevokedAt { get; set; }

    public DateTime CreatedDate { get; set; }

    public DateTime LastSentAt { get; set; }

    public string? RequestIp { get; set; }

    public string? RequestUserAgent { get; set; }

    public virtual User User { get; set; } = null!;
}
