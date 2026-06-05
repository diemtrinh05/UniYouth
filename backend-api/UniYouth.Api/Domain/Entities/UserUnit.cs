using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class UserUnit
{
    public int UserUnitID { get; set; }

    public int UserID { get; set; }

    public int UnitID { get; set; }

    public DateOnly JoinDate { get; set; }

    public int? PositionID { get; set; }

    public string? Position { get; set; }

    public byte? Status { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual Unit Unit { get; set; } = null!;

    public virtual Position? PositionNavigation { get; set; }

    public virtual User User { get; set; } = null!;
}
