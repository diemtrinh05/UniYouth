using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class Role
{
    public int RoleID { get; set; }

    public string RoleName { get; set; } = null!;

    public DateTime? CreatedDate { get; set; }

    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}
