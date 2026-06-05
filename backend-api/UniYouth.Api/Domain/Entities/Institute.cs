using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class Institute
{
    public int InstituteID { get; set; }

    public string InstituteName { get; set; } = null!;

    public string? Description { get; set; }

    public string? ContactEmail { get; set; }

    public byte? Status { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual ICollection<Event> Events { get; set; } = new List<Event>();

    public virtual ICollection<Unit> Units { get; set; } = new List<Unit>();
}
