using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class User
{
    public virtual ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
}
