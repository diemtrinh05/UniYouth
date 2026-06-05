using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class ActivityPoint
{
    public int PointID { get; set; }

    public int EventID { get; set; }

    public int UserID { get; set; }

    public int? EventPointID { get; set; }

    public int Points { get; set; }

    public string? PointType { get; set; }

    public int? AwardedBy { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual User? AwardedByNavigation { get; set; }

    public virtual Event Event { get; set; } = null!;

    public virtual EventPoint? EventPoint { get; set; }

    public virtual User User { get; set; } = null!;
}
