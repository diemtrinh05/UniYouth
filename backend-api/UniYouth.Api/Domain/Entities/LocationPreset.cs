using System;

namespace UniYouth.Api.Domain.Entities;

public partial class LocationPreset
{
    public int LocationPresetID { get; set; }

    public string Name { get; set; } = null!;

    public string? Address { get; set; }

    public decimal Latitude { get; set; }

    public decimal Longitude { get; set; }

    public int? RadiusMeters { get; set; }

    public int? InstituteID { get; set; }

    public bool IsActive { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime CreatedDate { get; set; }

    public DateTime UpdatedDate { get; set; }
}
