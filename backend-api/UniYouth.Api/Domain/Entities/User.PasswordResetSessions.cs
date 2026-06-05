using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class User
{
    public virtual ICollection<PasswordResetSession> PasswordResetSessions { get; set; } = new List<PasswordResetSession>();
}
