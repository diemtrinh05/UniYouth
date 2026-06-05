using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class SystemSetting
{
    public int SettingID { get; set; }

    public string SettingKey { get; set; } = null!;

    public string SettingValue { get; set; } = null!;

    public string? DataType { get; set; }

    public string? Description { get; set; }

    public int? UpdatedBy { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual User? UpdatedByNavigation { get; set; }
}
