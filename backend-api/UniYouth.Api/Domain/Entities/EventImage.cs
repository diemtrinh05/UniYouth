using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class EventImage
{
    public int ImageID { get; set; }

    public int EventID { get; set; }

    public string ImageUrl { get; set; } = null!;

    public string? ImageType { get; set; }

    public string? Caption { get; set; }

    public int? DisplayOrder { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual Event Event { get; set; } = null!;
}
