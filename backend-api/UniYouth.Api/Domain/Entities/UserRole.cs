using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class UserRole
{
    public int UserRoleID { get; set; }

    public int UserID { get; set; }

    public int RoleID { get; set; }

    public DateTime? AssignDate { get; set; }

    public virtual Role Role { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
