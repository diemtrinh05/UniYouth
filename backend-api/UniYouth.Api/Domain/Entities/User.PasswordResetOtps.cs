using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class User
{
    public virtual ICollection<PasswordResetOtp> PasswordResetOtps { get; set; } = new List<PasswordResetOtp>();
}
