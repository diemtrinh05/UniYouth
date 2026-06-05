using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class EventType
{
    public int TypeID { get; set; }

    public string TypeName { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual ICollection<Event> Events { get; set; } = new List<Event>();
}
