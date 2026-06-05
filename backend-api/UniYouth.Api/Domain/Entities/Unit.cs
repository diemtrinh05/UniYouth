using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class Unit
{
    public int UnitID { get; set; }

    public string UnitName { get; set; } = null!;

    public string UnitType { get; set; } = null!;

    public int InstituteID { get; set; }

    public int? ParentUnitID { get; set; }

    public string? Description { get; set; }

    public byte? Status { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual Institute Institute { get; set; } = null!;

    public virtual ICollection<Unit> InverseParentUnit { get; set; } = new List<Unit>();

    public virtual Unit? ParentUnit { get; set; }

    public virtual ICollection<Position> Positions { get; set; } = new List<Position>();

    public virtual ICollection<UserUnit> UserUnits { get; set; } = new List<UserUnit>();
}
