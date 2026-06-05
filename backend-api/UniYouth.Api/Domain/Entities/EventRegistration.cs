using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class EventRegistration
{
    public int RegistrationID { get; set; }

    public int EventID { get; set; }

    public int UserID { get; set; }

    public DateTime? RegisterTime { get; set; }

    public byte? Status { get; set; }

    public string? CancellationReason { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual Event Event { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
