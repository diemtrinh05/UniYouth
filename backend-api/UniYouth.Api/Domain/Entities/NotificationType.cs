using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class NotificationType
{
    public int TypeID { get; set; }

    public string TypeName { get; set; } = null!;

    public string? Template { get; set; }

    public string? Locale { get; set; }

    public int? TemplateVersion { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
}
