using System;

namespace UniYouth.Api.Domain.Entities;

public partial class PasswordResetToken
{
    public int Id { get; set; }

    public int UserID { get; set; }

    /// <summary>
    /// Token đã được băm (hash) trước khi lưu để giảm rủi ro nếu DB bị lộ.
    /// </summary>
    public string Token { get; set; } = null!;

    public DateTime ExpiredAt { get; set; }

    public bool IsUsed { get; set; }

    public DateTime CreatedDate { get; set; }

    public virtual User User { get; set; } = null!;
}
