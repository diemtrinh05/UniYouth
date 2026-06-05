using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class Event
{
    public int EventID { get; set; }

    public string EventName { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public string? LocationName { get; set; }

    public decimal? Latitude { get; set; }

    public decimal? Longitude { get; set; }

    public int? AllowRadius { get; set; }

    public int? MaxParticipants { get; set; }

    public int? CurrentParticipants { get; set; }

    public int CreatedBy { get; set; }

    public int EventTypeID { get; set; }

    public int? InstituteID { get; set; }

    public byte? Status { get; set; }

    public bool EnableFaceVerification { get; set; }

    public DateTime? RegistrationDeadline { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual ICollection<ActivityPoint> ActivityPoints { get; set; } = new List<ActivityPoint>();

    public virtual ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();

    public virtual User CreatedByNavigation { get; set; } = null!;

    public virtual ICollection<EventImage> EventImages { get; set; } = new List<EventImage>();

    public virtual ICollection<EventPoint> EventPoints { get; set; } = new List<EventPoint>();

    public virtual ICollection<EventQRCode> EventQRCodes { get; set; } = new List<EventQRCode>();

    public virtual ICollection<EventRegistration> EventRegistrations { get; set; } = new List<EventRegistration>();

    public virtual EventType EventType { get; set; } = null!;

    public virtual Institute? Institute { get; set; }

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
}
