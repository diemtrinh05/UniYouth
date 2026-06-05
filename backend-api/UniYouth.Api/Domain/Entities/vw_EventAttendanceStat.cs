using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class vw_EventAttendanceStat
{
    public int EventID { get; set; }

    public string EventName { get; set; } = null!;

    public DateTime StartTime { get; set; }

    public int? MaxParticipants { get; set; }

    public int? TotalRegistrations { get; set; }

    public int? ValidAttendances { get; set; }

    public int? InvalidAttendances { get; set; }

    public decimal? AttendanceRate { get; set; }
}
