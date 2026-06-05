using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class Position
{
    public int PositionID { get; set; }

    public string PositionCode { get; set; } = null!;

    public string PositionName { get; set; } = null!;

    public int UnitID { get; set; }

    public byte? IsActive { get; set; }

    public int? SortOrder { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual Unit Unit { get; set; } = null!;

    public virtual ICollection<UserUnit> UserUnits { get; set; } = new List<UserUnit>();
}
