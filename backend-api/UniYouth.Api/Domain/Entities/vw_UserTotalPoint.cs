using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class vw_UserTotalPoint
{
    public int UserID { get; set; }

    public string FullName { get; set; } = null!;

    public string Code { get; set; } = null!;

    public int TotalPoints { get; set; }

    public int? EventsParticipated { get; set; }

    public int? ValidAttendances { get; set; }
}

