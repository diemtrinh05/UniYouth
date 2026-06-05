using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class EventQRCode
{
    public int QRID { get; set; }

    public int EventID { get; set; }

    public string QRToken { get; set; } = null!;

    public DateTime ValidFrom { get; set; }

    public DateTime ValidUntil { get; set; }

    public bool? IsActive { get; set; }

    public int? ScanLimit { get; set; }

    public int? CurrentScans { get; set; }

    public int CreatedBy { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();

    public virtual User CreatedByNavigation { get; set; } = null!;

    public virtual Event Event { get; set; } = null!;
}
