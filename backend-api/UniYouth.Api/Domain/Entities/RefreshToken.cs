using System;

namespace UniYouth.Api.Domain.Entities;

public partial class RefreshToken
{
    public int RefreshTokenID { get; set; }

    public int UserID { get; set; }

    public string TokenHash { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }

    public DateTime? LastUsedAt { get; set; }

    public DateTime? RevokedAt { get; set; }

    public string? ReplacedByTokenHash { get; set; }

    public string? CreatedByIp { get; set; }

    public string? CreatedByUserAgent { get; set; }

    public string? RevokedByIp { get; set; }

    public string? RevokedByUserAgent { get; set; }

    public string? RevokedReason { get; set; }

    public DateTime CreatedDate { get; set; }

    public DateTime UpdatedDate { get; set; }

    public virtual User User { get; set; } = null!;
}
