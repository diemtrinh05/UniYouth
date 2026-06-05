using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class User
{
    public virtual ICollection<PasswordResetToken> PasswordResetTokens { get; set; } = new List<PasswordResetToken>();
}
