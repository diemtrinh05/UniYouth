using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class EventPoint
{
    public int EventPointID { get; set; }

    public int EventID { get; set; }

    public string RoleType { get; set; } = null!;

    public int Points { get; set; }

    public string? Description { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual ICollection<ActivityPoint> ActivityPoints { get; set; } = new List<ActivityPoint>();

    public virtual Event Event { get; set; } = null!;
}
